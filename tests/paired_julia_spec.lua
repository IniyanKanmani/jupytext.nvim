local util = require('tests.test_util')
local get_metadata = require('jupytext').get_metadata
local read_file = require('jupytext').read_file

describe('a paired .ipynb julia file', function()
  local notebooks = util.notebooks()
  print(notebooks)
  local ipynb_file = notebooks .. 'julia.ipynb'

  it('has jupytext metadata', function()
    local metadata = get_metadata(read_file(ipynb_file, true))
    assert.is_truthy(metadata.jupytext)
  end)

  it('can be loaded with automatic filetype "julia"', function()
    require('jupytext').setup({ format = 'script' })
    vim.cmd('edit ' .. ipynb_file)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.are.same(lines[1], '# ---') -- YAML header, not JSON
    assert.are.same(vim.bo.filetype, 'julia')
  end)

  it('can be edited and retain outputs and pairings', function()
    require('jupytext').setup({ format = 'script', async_write = false })
    vim.cmd('edit ' .. ipynb_file)
    vim.cmd('%s/World//g')
    vim.cmd.write()
    local json = require('jupytext').get_json(ipynb_file)
    assert.are.same(json.metadata.jupytext.formats, 'ipynb,jl:percent')
    assert.is_truthy(json.cells[5].source[1]:find('Hello'))
    assert.is_nil(json.cells[5].source[1]:find('World'))
    assert.is_true(#json.cells[5].outputs > 0)
  end)

  it('loses outputs but keeps pairings if saved with `update = false`', function()
    require('jupytext').setup({ format = 'script', async_write = false, update = false })
    vim.cmd('edit ' .. ipynb_file)
    vim.cmd.write()
    local json = require('jupytext').get_json(ipynb_file)
    assert.are.same(json.metadata.jupytext.formats, 'ipynb,jl:percent')
    assert.is_true(#json.cells[5].outputs == 0)
  end)
end)
