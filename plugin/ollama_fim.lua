local M = {}

-- HTTP request function
local function send_request(prompt)
  local curl = vim.fn.systemlist
  local response = curl({
    "curl", "-X", "POST", "http://localhost:11400/generate",
    "-H", "Content-Type: application/json",
    "-d", vim.fn.json_encode({
      prompt = prompt,
      model = "fim",
      stream = false
    })
  })

  if vim.v.shell_error ~= 0 then
    print("Failed to connect to Ollama.")
    return nil
  end

  local decoded = vim.fn.json_decode(table.concat(response, "\n"))
  return decoded and decoded.choices and decoded.choices[1].text or nil
end

-- Capture surrounding code context
local function get_context()
  -- Use the current line as context; extend as needed for more lines
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local line_num, col = cursor_pos[1], cursor_pos[2]

  local prefix = lines[line_num - 1]:sub(1, col)
  local suffix = lines[line_num - 1]:sub(col + 1)

  return prefix, suffix
end

-- Insert FIM completion
function M.complete_code()
  local prefix, suffix = get_context()
  local prompt = '<PRE> ' + prefix + '<SUF> ' + suffix + '<MID>'

  local completion = send_request(prompt)
  if completion then
    -- Insert the completion at the cursor position
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row, col = cursor[1], cursor[2]
    vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { completion })
  else
    print("No completion received.")
  end
end

-- Set up key binding
function M.setup()
  vim.api.nvim_set_keymap("n", "<leader>cc", "<cmd>lua require('ollama_fim').complete_code()<CR>", { noremap = true, silent = true })
end

return M
