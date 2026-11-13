return {
    coordinates_helper = require("prettymap/luaflet/twigs/coordinates_helper"),
    coord = require("prettymap/luaflet/twigs/coordinates_helper").coord,
    coordFine = require("prettymap/luaflet/twigs/coordinates_helper").coordFine,
    twigs = {
        prefab = {
            FloorControlTwig = require("prettymap/luaflet/twigs/prefab/FloorControlTwig"),
            ZoomControlTwig = require("prettymap/luaflet/twigs/prefab/ZoomControlTwig"),
        },
        Twig = require("prettymap/luaflet/twigs/Twig"),
        StaticTwig = require("prettymap/luaflet/twigs/StaticTwig"),
        SpriteTwig = require("prettymap/luaflet/twigs/SpriteTwig"),
        PolygonTwig = require("prettymap/luaflet/twigs/PolygonTwig"),
        GridTwig = require("prettymap/luaflet/twigs/GridTwig"),
    },
    Tooltip = require("prettymap/luaflet/Tooltip"),
}
