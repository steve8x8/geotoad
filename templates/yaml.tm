template = {

  # map wp to guid in yaml form
  # (to be added to mapping.yaml)

  'yaml' => {
    'ext'  => 'yaml',
    'desc' => 'mapping.yaml entries',
    'templatePre' => "---\n",
    'templateWP'  => "<%out.wid%>: <%out.guid%>\n"
  },

}
