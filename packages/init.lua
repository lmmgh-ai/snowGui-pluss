Packages_path = ...
--全局包管理
packages = {
    __path = {
        --name=path
    }, --扫描包中所有文件路径
    scene_manager = require(Packages_path .. "/scene_manager"),
    snowGui = require(Packages_path .. "/snowGui"),
    module_loader = require(Packages_path .. "/module_loader"),
}

return packages
