local util = require('tests.test_util')
local get_metadata = require('jupytext').get_metadata
local read_file = require('jupytext').read_file

describe('a paired .ipynb python file', function()
  local notebooks = util.notebooks()
  print(notebooks)
  local ipynb_file = notebooks .. 'paired.ipynb'

  it('has jupytext metadata', function()
    local metadata = get_metadata(read_file(ipynb_file, true))
    assert.is_truthy(metadata.jupytext)
  end)

  it('can be loaded with automatic filetype "python"', function()
    require('jupytext').setup({ format = 'script' })
    vim.cmd('edit ' .. ipynb_file)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.are.same(lines[1], '# ---') -- YAML header, not JSON
    assert.are.same(vim.bo.filetype, 'python')
  end)

  it('can be edited and retain outputs', function()
    require('jupytext').setup({ format = 'script', async_write = false })
    vim.cmd('edit ' .. ipynb_file)
    vim.cmd('%s/World//g')
    vim.cmd.write()
    local json = require('jupytext').get_json(ipynb_file)
    assert.are.same(json.metadata.jupytext.formats, 'ipynb,py:light,md:myst')
    assert.is_truthy(json.cells[5].source[1]:find('Hello'))
    assert.is_nil(json.cells[5].source[1]:find('World'))
    assert.is_true(#json.cells[5].outputs > 0)
  end)

  it('loses pairing and outputs when saved to different .ipynb file', function()
    require('jupytext').setup({ format = 'script', async_write = false })
    vim.cmd('edit ' .. ipynb_file)
    local outfile = notebooks .. 'paired_unpaired.ipynb'
    vim.cmd.write(outfile)
    local json = require('jupytext').get_json(outfile)
    assert.is_nil(json.metadata.jupytext)
    assert.is_true(#json.cells[5].outputs == 0)
  end)

  it('can be saved to a plain text file', function()
    require('jupytext').setup({ format = 'script', async_write = false })
    vim.cmd('edit ' .. ipynb_file)
    local outfile = notebooks .. 'paired_unpaired.py'
    vim.cmd.write(outfile)
    local text = require('jupytext').read_file(outfile)
    assert.is_true(text:sub(1, 5) == '# ---')
  end)

  it('loses pairing when saved with `autosync = false`', function()
    require('jupytext').setup({ format = 'script', async_write = false, autosync = false })
    vim.cmd('edit ' .. ipynb_file)
    vim.cmd.write()
    local json = require('jupytext').get_json(ipynb_file)
    assert.is_nil(json.metadata.jupytext)
    assert.is_true(#json.cells[5].outputs > 0)
  end)
end)
