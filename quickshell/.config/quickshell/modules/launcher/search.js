// search.js -- ranking for the app launcher.
//
// Pure functions, no QML objects, so this can be a shared library instance.
// The aim is wofi's behaviour plus two things it lacked: matches are ranked
// rather than merely filtered, and apps you actually launch drift to the top.
.pragma library

// Characters that start a new "word", so a query can jump to it. Matching
// "code" against "Visual Studio Code" should beat matching it inside "Barcode".
var BOUNDARY = " -_/.:()[]";

// How well `hay` matches `needle` (already lowercased). 0 means no match.
// The tiers are far enough apart that a weaker field can never outrank a
// stronger kind of match on the name -- see WEIGHTS below.
function matchScore(hay, needle) {
    if (!hay)
        return 0;
    var h = hay.toLowerCase();

    if (h === needle)
        return 1000;

    var at = h.indexOf(needle);
    if (at === 0)
        return 800 - Math.min(h.length - needle.length, 40);
    if (at > 0) {
        var boundary = BOUNDARY.indexOf(h.charAt(at - 1)) >= 0;
        // Earlier hits win, but only slightly: position is a tiebreak, not a tier.
        return (boundary ? 600 : 400) - Math.min(at, 40);
    }

    return subsequence(h, needle);
}

// Scattered-letter fallback: "gimp" finds "GNU Image Manipulation Program".
// Consecutive and word-initial hits score higher, so this stays useful rather
// than matching everything with the right letters in it.
function subsequence(h, needle) {
    var pos = 0;
    var streak = 0;
    var total = 0;

    for (var i = 0; i < needle.length; i++) {
        var found = h.indexOf(needle.charAt(i), pos);
        if (found < 0)
            return 0;

        streak = (found === pos) ? streak + 1 : 0;
        total += 4 + streak * 3;
        if (found > 0 && BOUNDARY.indexOf(h.charAt(found - 1)) >= 0)
            total += 6;
        total -= Math.min(found - pos, 6);   // penalise long jumps between letters

        pos = found + 1;
    }
    // Capped below the substring tier: a real substring hit always wins.
    return Math.max(1, Math.min(total, 250));
}

// Which fields are searched, and how much a hit in each is worth. The name is
// what people type; a comment hit is a last resort, so it is scaled right down.
var WEIGHTS = [
    { field: "name",        weight: 1.0 },
    { field: "actionName",  weight: 0.9 },
    { field: "id",          weight: 0.7 },
    { field: "keywords",    weight: 0.6 },
    { field: "genericName", weight: 0.5 },
    { field: "comment",     weight: 0.3 }
];

// Best score across every field of one entry. `query` is lowercased by the caller.
function scoreEntry(rec, query) {
    if (!query)
        return 1;

    var best = 0;
    for (var i = 0; i < WEIGHTS.length; i++) {
        var w = WEIGHTS[i];
        var value = rec[w.field];
        if (!value)
            continue;

        var hit = 0;
        if (Array.isArray(value)) {
            for (var k = 0; k < value.length; k++)
                hit = Math.max(hit, matchScore(value[k], query));
        } else {
            hit = matchScore(value, query);
        }

        best = Math.max(best, hit * w.weight);
    }
    return best;
}

// Launch history nudges the ranking instead of dictating it, so typing a name
// exactly still beats a favourite that merely fuzzy-matches. Logarithmic, so
// the app you open fifty times a day does not permanently own the first row.
function frecencyBonus(uses) {
    if (!uses)
        return 0;
    return Math.min(120, 40 * Math.log(1 + uses));
}

// Rank `records` for `query`. Returns a new sorted array of the matches.
// With no query this is pure history, which makes an empty launcher useful:
// the apps you open most are already under the cursor.
function rank(records, query, uses) {
    var q = query.trim().toLowerCase();
    var out = [];

    for (var i = 0; i < records.length; i++) {
        var rec = records[i];
        var base = scoreEntry(rec, q);
        if (base <= 0)
            continue;

        var used = uses[rec.key] || 0;
        out.push({
            rec: rec,
            used: used,
            score: base + frecencyBonus(used)
        });
    }

    out.sort(function (a, b) {
        if (b.score !== a.score)
            return b.score - a.score;
        if (b.used !== a.used)
            return b.used - a.used;
        return a.rec.name.localeCompare(b.rec.name);
    });

    var ranked = [];
    for (var j = 0; j < out.length; j++)
        ranked.push(out[j].rec);
    return ranked;
}
