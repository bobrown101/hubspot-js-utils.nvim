# hubspot-js-utils.nvim
A collection of utils that make life easier while writing frontend code at hubspot

## Install
```lua

    use({"bobrown101/plugin-utils.nvim"})

    use({
        "bobrown101/hubspot-js-utils.nvim",
        requires = {"bobrown101/plugin-utils.nvim"},
        config = function() require("hubspot-js-utils").setup({}) end
    })

```

## test_file()
```lua
:lua require('hubspot-js-utils').test_file()
```

Will open the test file of the current buffer. If it already exists it will open it.
