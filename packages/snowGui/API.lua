--设置包索引
if lumenGui_path == nil then
    lumenGui_path = (...):match("(.-)[^%.]+$")
end

lumenGui_FILE_PATH       = debug.getinfo(1, 'S').source:match("^@(.+)/")
lumenGui_FILE_PATH       = lumenGui_FILE_PATH == nil and "" or lumenGui_FILE_PATH
--font
ChineseFont              = (lumenGui_path .. "/font/YeZiGongChangTangYingHei-2.ttf")
--字体文件路径全局索引方便加载
--view
local view               = require(lumenGui_path .. ".view.view")
local button             = require(lumenGui_path .. ".view.button")
local switch_button      = require(lumenGui_path .. ".view.switch_button")
local slider             = require(lumenGui_path .. ".view.slider")
local list               = require(lumenGui_path .. ".view.list")
local text               = require(lumenGui_path .. ".view.text")
local edit_text          = require(lumenGui_path .. ".view.edit_text")
local input_text         = require(lumenGui_path .. ".view.input_text")
local image              = require(lumenGui_path .. ".view.image")
local select_button      = require(lumenGui_path .. ".view.select_button")
local select_menu        = require(lumenGui_path .. ".view.select_menu")
local dialog             = require(lumenGui_path .. ".container.dialog")
--layout
local line_layout        = require(lumenGui_path .. ".layout.line_layout")
local gravity_layout     = require(lumenGui_path .. ".layout.gravity_layout")
local grid_layout        = require(lumenGui_path .. ".layout.grid_layout")
local frame_layout       = require(lumenGui_path .. ".layout.frame_layout")
--container
local title_menu         = require(lumenGui_path .. ".container.title_menu")
local tab_control        = require(lumenGui_path .. ".container.tab_control")
local border_container   = require(lumenGui_path .. ".container.border_container")
local fold_container     = require(lumenGui_path .. ".container.fold_container")
local slider_container   = require(lumenGui_path .. ".container.slider_container")
local window             = require(lumenGui_path .. ".container.window")
local tree_manager       = require(lumenGui_path .. ".container.tree_manager")
--function_widget
local scene_2D_guiEditor = require(lumenGui_path .. ".function_widget.scene_2D_guiEditor")
local scene_2D           = require(lumenGui_path .. ".function_widget.scene_2D")
local sandbox            = require(lumenGui_path .. ".function_widget.sandbox")
local file_select_dialog = require(lumenGui_path .. ".function_widget.file_select_dialog")
--libs
local Camera             = require(lumenGui_path .. ".libs.Camera.Camera")
local Color              = require(lumenGui_path .. ".libs.Color.Color")
local events_system      = require(lumenGui_path .. ".libs.events_system")
local font_manger        = require(lumenGui_path .. ".libs.font_manger") --单例模式
local CustomPrint        = require(lumenGui_path .. ".libs.CustomPrint")
local debugGraph         = require(lumenGui_path .. ".libs.debugGraph")
local nativefs           = require(lumenGui_path .. ".libs.nativefs")
local fun                = require(lumenGui_path .. ".libs.fun")
--
local API                = {
    view = view,
    button = button,
    switch_button = switch_button,
    text = text,
    edit_text = edit_text,
    input_text = input_text,
    select_button = select_button,
    select_menu = select_menu,
    list = list,
    slider = slider,
    image = image,
    --
    line_layout = line_layout,
    gravity_layout = gravity_layout,
    grid_layout = grid_layout,
    frame_layout = frame_layout,
    --
    border_container = border_container,
    tab_control = tab_control,
    window = window,
    title_menu = title_menu,
    fold_container = fold_container,
    slider_container = slider_container,
    tree_manager = tree_manager,
    dialog = dialog,
    --
    scene_2D = scene_2D,
    scene_2D_guiEditor = scene_2D_guiEditor,
    sandbox = sandbox,
    file_select_dialog = file_select_dialog,
    --
    Camera = Camera,
    Color = Color,
    events_system = events_system,
    font_manger = font_manger,
    CustomPrint = CustomPrint,
    fun = fun,
    nativefs = nativefs,
    debugGraph = debugGraph
}


return API;
