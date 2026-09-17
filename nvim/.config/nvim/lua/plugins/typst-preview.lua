return {

  'chomosuke/typst-preview.nvim',

  lazy = false, -- or ft = 'typst'

  version = '1.*',

  opts = {args = { "--font-path", "fonts" },}, -- lazy.nvim will implicitly calls `setup {}`

}
