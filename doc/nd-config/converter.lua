function Header(el)
  -- io.stderr:write("\nBEFORE HEADER CLASSES: " .. table.concat(el.classes, ", ") .. "\n")
  if el.level == 1 then
      el.classes:insert("CTitle")
  else
      el.classes:insert("CHeading")
  end
  -- io.stderr:write("AFTER HEADER CLASSES: " .. table.concat(el.classes, ", ") .. "\n")
  return el
end

function CodeBlock(block)
  -- io.stderr:write("\nPROCESSING CODE BLOCK\n")
  block.classes:insert("CCode")
  -- io.stderr:write("CODE BLOCK CLASSES: " .. table.concat(block.classes, ", ") .. "\n")
  return pandoc.Div(block, {class = "CTopic"})
end
