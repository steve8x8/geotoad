template = {

  'csv' => {
    'ext'  => 'txt',
    'desc' => 'CSV for spreadsheet imports',
    'templatePre' =>
      "\"Name\",\"Waypoint ID\",\"Creator\",\"Difficulty\",\"Terrain\"," +
      "\"Latitude\",\"Longitude\",\"Type\",\"Size\",\"Creation Date\",\"Details\"\n",
    'templateWP'  =>
      "\"<%wp.name%>\",\"<%out.wid%>\",\"<%wp.creator%>\"," +
      "<%wp.difficulty%>,<%wp.terrain%>,\"<%wp.latwritten%>\",\"<%wp.lonwritten%>\"," +
      "\"<%wp.type%>\",\"<%wp.size%>\",\"<%out.cdate%>\",\"<%outText.short_desc%> <%outText.long_desc%>\"\n"
  },

}
