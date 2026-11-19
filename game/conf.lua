function love.conf(t)
  t.identity = "r36sromsstore"
  t.version = "11.5"
  t.window.title = "R36S ROMS STORE"
  -- Em alguns firmwares KMSDRM, 0x0 usa o modo SDL legado 640x480
  -- mesmo quando o painel Linux e 720x720. Consultar fb0/DRM ANTES de
  -- abrir a janela. Se o backend nao aceitar o modo, o renderizador
  -- compensa a escala fisica sem alterar o sistema ou os jogos.
  t.window.width = 0
  t.window.height = 0
  local ok, detector = pcall(require, "core.display")
  if ok and detector then
    local found, w, h = pcall(detector.probe_physical)
    if found and w and h then
      t.window.width, t.window.height = w, h
    end
  end
  t.window.fullscreen = true
  t.window.resizable = false
  t.window.vsync = 1
  t.modules.joystick = true
  t.modules.audio = true
  t.modules.sound = true
  t.modules.physics = false
  t.modules.video = false
  t.modules.mouse = true
  t.modules.touch = false

  -- Testes no PC: R36SBR_WINDOWED=1 abre uma janela 640x480
  if os.getenv("R36SBR_WINDOWED") then
    t.window.width = 640
    t.window.height = 480
    t.window.fullscreen = false
  end
end
