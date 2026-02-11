require'shade'.setup({
  overlay_opacity = 50,
  opacity_step = 1,
  keys = {
    brightness_up    = '<M-Up>',
    brightness_down  = '<M-Down>',
    toggle           = '<Leader>p',
  }
})

require'twilight'.setup({
  dimming = {
    alpha = 0.50, -- amount of dimming
  },
})
