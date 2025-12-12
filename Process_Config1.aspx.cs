using DocumentFormat.OpenXml.ExtendedProperties;
using DocumentFormat.OpenXml.Spreadsheet;
using Org.BouncyCastle.Ocsp;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;
public partial class Process_Config : System.Web.UI.Page
{
    static DataTable dt = new DataTable();
    static SqlCmd SqlCmd = new SqlCmd();
    static string[] Param = new string[30];
    static string[] PName = new string[30];
    int Count = 0;
    static string userId = ""; static string companyn = "";
    static string login_user = "";

    protected void Page_Load(object sender, EventArgs e)
    {
        if (HttpContext.Current.Session["UserId"] == null)
        {
            Response.Redirect("/templates/login/LoginMain.aspx");


        }
        else
        {
            login_user = HttpContext.Current.Session["USERNAME"].ToString();
            userId = HttpContext.Current.Session["UserId"].ToString();
            ClientScript.RegisterStartupScript(this.GetType(), "setUserId",
                 "var loggedUserId = '" + userId + "';", true);
            //  companyn = HttpContext.Current.Session["TABLE_USER_NAME"].ToString();
            companyn = HttpContext.Current.Session["StackHolderId"].ToString();
        }
        if (!IsPostBack)
        {
            // BindGenName();
        }
    }

    [System.Web.Services.WebMethod]
    public static List<string> GetAllowedUserIds()
    {
        List<string> allowed = new List<string>();


        DataTable dt = SqlCmd.SelectDatakpcl("SP_GETALLOWED_USER", Param, PName, 0);

        foreach (DataRow row in dt.Rows)
        {
            allowed.Add(row["DESGID"].ToString());
        }

        return allowed;
    }



    [WebMethod]
    public static List<object> GetEscoms()
    {
        try
        {


            var temp = HttpContext.Current.Session["TABLE_USER_ID"].ToString();
            Param[0] = HttpContext.Current.Session["TABLE_USER_ID"].ToString();
            PName[0] = "@GETID";

            DataTable dt;

            if (new[] { "100001", "300001", "400001", "500001", "200001" }.Contains(temp))
            {
                dt = SqlCmd.SelectDatakpcl("SP_GET_ESCOMS", Param, PName, 1);
            }
            else
            {
                dt = SqlCmd.SelectQuerykpcl("SP_GET_ESCOMS");
            }
            //  DataTable dt = SqlCmd.SelectQuerykpcl("SP_GET_ESCOMS");

            var list = new List<object>();
            foreach (DataRow row in dt.Rows)
            {
                list.Add(new
                {
                    CMID = row["COMPID"].ToString(),
                    CMNAME = row["CMNAME"].ToString()
                });
            }

            return list;
        }
        catch (Exception ex)
        {
            throw new Exception("Error fetching ESCOM data: " + ex.Message);
        }
    }


    [WebMethod]
    public static List<object> Get_DATA()
    {
        dt = SqlCmd.SelectDatakpcl("SP_FORM_DETAIL_V1", null, null, 0);

        var list = new List<object>();

        foreach (DataRow row in dt.Rows)
        {
            list.Add(new
            {
                FORMURL = row["FORMURL"].ToString(),
                FORMID = row["FORMID"].ToString(),
                FORMNAMES = row["FORMNAMES"].ToString(),
                MODULEID = row["MODULEID"].ToString(),
                MODULENAME = row["MODULENAME"].ToString()
            });
        }

        return list;
    }



    public class DesignationModel
    {
        public string ID { get; set; }
        public string Name { get; set; }
    }

    [WebMethod]
    public static List<DesignationModel> GetAssignedDesignations(string escom, string Stack_Id)
    {
        List<DesignationModel> list = new List<DesignationModel>();

        Param[0] = escom;
        PName[0] = "@Escom";


        Param[1] = Stack_Id;
        PName[1] = "@STACKHOLDER_ID";

        DataTable dt = SqlCmd.SelectDatakpcl("SP_USER_DETAILS_V1", Param, PName, 2);

        foreach (DataRow dr in dt.Rows)
        {
            list.Add(new DesignationModel()
            {
                ID = dr["ID"].ToString(),
                Name = dr["FULLNAME"].ToString()
            });
        }

        return list;
    }


    [WebMethod]
    public static List<DesignationModel> StakeHolders(string ESCOM_ID)
    {
        List<DesignationModel> list = new List<DesignationModel>();

        Param[0] = ESCOM_ID;
        PName[0] = "@ESCOM_ID";

        DataTable dt = SqlCmd.SelectDatakpcl("SP_GET_STACKHOLDERS", Param, PName, 1);

        foreach (DataRow dr in dt.Rows)
        {
            list.Add(new DesignationModel()
            {
                ID = dr["STACKHOLDER_ID"].ToString(),
                Name = dr["STACKHOLDER_NAME"].ToString()
            });
        }

        return list;
    }


    [WebMethod]
    public static string SavePermissions(Dictionary<string, string> permissionsData)
    {
        try
        {
            // Extract values safely
            string ESCOM_ID = permissionsData.ContainsKey("ESCOM_ID") ? permissionsData["ESCOM_ID"] : "";
            string FormID = permissionsData.ContainsKey("FormID") ? permissionsData["FormID"] : "";
            string FormName = permissionsData.ContainsKey("FormName") ? permissionsData["FormName"] : "";
            string FormURL = permissionsData.ContainsKey("FormURL") ? permissionsData["FormURL"] : "";
            string ModuleID = permissionsData.ContainsKey("ModuleID") ? permissionsData["ModuleID"] : "";
            string Stakeholder_ID = permissionsData.ContainsKey("Stakeholder_ID") ? permissionsData["Stakeholder_ID"] : "";

            string Read_DesignationIDs = permissionsData.ContainsKey("Read_DesignationIDs")
                                         ? permissionsData["Read_DesignationIDs"] : "";

            string ReadWrite_DesignationIDs = permissionsData.ContainsKey("ReadWrite_DesignationIDs")
                                              ? permissionsData["ReadWrite_DesignationIDs"] : "";

            string Sequence = permissionsData.ContainsKey("Sequence") ? permissionsData["Sequence"] : "";

            string createdBy = HttpContext.Current.Session["TABLE_USER_ID"].ToString();

            string EscomNmae = permissionsData.ContainsKey("ESCOM_Name") ? permissionsData["ESCOM_Name"] : "";


            login_user = HttpContext.Current.Session["USERNAME"].ToString();
            userId = HttpContext.Current.Session["UserId"].ToString();
            string[] Param = new string[13];
            string[] PName = new string[13];

            Param[0] = ESCOM_ID;
            PName[0] = "@ESCOMID";

            Param[1] = FormID;
            PName[1] = "@FORMID";

            Param[2] = FormName.Trim();
            PName[2] = "@FORMNAME";

            Param[3] = FormURL;
            PName[3] = "@FORMURL";

            Param[4] = ModuleID;
            PName[4] = "@MODULEID";

            Param[5] = Read_DesignationIDs;
            PName[5] = "@PREAD";

            Param[6] = ReadWrite_DesignationIDs;
            PName[6] = "@PWRITE";

            Param[7] = Sequence;
            PName[7] = "@SEQUENANCE";

            Param[8] = login_user;
            PName[8] = "@CREATEDBY";

            Param[9] = userId;
            PName[9] = "@DESGID";

            Param[10] = login_user;
            PName[10] = "@DESG";

            Param[11] = EscomNmae;
            PName[11] = "@ESCOM_NAME";

            Param[12] = Stakeholder_ID;
            PName[12] = "@STACKHOLDER_ID";

            SqlCmd.ExecNonQuerykpcl("SP_SAVE_PROCESS_DETAILS", Param, PName, 13);

            return "Success";
        }
        catch (Exception ex)
        {
            return "Error: " + ex.Message;
        }
    }

    [WebMethod]
    public static string GetProcessDetails(string ESCOM_ID)
    {
        try
        {
            string[] Param = new string[1];
            string[] PName = new string[1];

            Param[0] = ESCOM_ID;
            PName[0] = "@ESCOMID";

            DataTable dt = SqlCmd.SelectDatakpcl("SP_GET_PROCESS_DETAILS", Param, PName, 1);

            string json = Newtonsoft.Json.JsonConvert.SerializeObject(dt);

            return json;
        }
        catch (Exception ex)
        {
            return "Error: " + ex.Message;
        }
    }



}