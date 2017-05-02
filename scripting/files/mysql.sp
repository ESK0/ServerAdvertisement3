public bool SA_MySQLConnect()
{
  hDB = SQL_Connect("sa3",true, sDBerror, sizeof(sDBerror));
  if(hDB == null)
  {
    SQL_GetError(hDB, sDBerror, sizeof(sDBerror));
    SetFailState("%s Cannot connect to the DB:\n %s\n\n\n", SA3, sDBerror);
  }
  else
  {
    PrintToServer("%s Connected to MySQL successfuly!", SA3);
    SQL_Query(hDB, "SET CHARACTER SET utf8");
    return true;
  }
  return false;
}
public bool SA_MySQLCheckTables()
{
  return false;
}
