using ClosedXML.Excel;
using DocumentFormat.OpenXml.Spreadsheet;
using iTextSharp.text;
using iTextSharp.text.pdf;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.Script.Services;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;
using Font = iTextSharp.text.Font;

public partial class CGS_Frm_Formula_Maker : System.Web.UI.Page
{
    static SqlCmd SqlCmd = new SqlCmd();
    static string[] Param = new string[40];
    static string[] PName = new string[40];
    static string[] Param1 = new string[40];
    static string[] PName1 = new string[40];
    static int Count = 0;
    static string login_user = "";
    static string companyn = "";
    static string userId = "";
    static int FormId = 106;

    protected void Page_Load(object sender, EventArgs e)
    {
        if (HttpContext.Current.Session["UserId"] == null)
        {
            Response.Redirect("/templates/login/LoginMain.aspx");
        }
        else
        {
            string login_user = HttpContext.Current.Session["USERNAME"].ToString();
            userId = HttpContext.Current.Session["UserId"].ToString();
            ClientScript.RegisterStartupScript(this.GetType(), "setUserId",
                 "var loggedUserId = '" + userId + "';", true);
            companyn = HttpContext.Current.Session["StackHolderId"].ToString();
        }
        if (!IsPostBack)
        {
        }
    }

    [WebMethod]
    public static string GetThermalTerms()
    {
        try
        {
            DataTable dt = SqlCmd.SelectDatakpcl("SP_GET_THERMAL_TERM", null, null, 0);

            if (dt != null && dt.Rows.Count > 0)
            {
                var serializer = new JavaScriptSerializer();
                var rows = new List<Dictionary<string, object>>();

                foreach (DataRow row in dt.Rows)
                {
                    var dict = new Dictionary<string, object>();
                    dict["TID"] = row["TID"];
                    dict["TERM_NAME"] = row["TERM_NAME"];
                    dict["TERM_DESCRIPTION"] = row["TERM_DESCRIPTION"];
                    rows.Add(dict);
                }

                return serializer.Serialize(new { success = true, data = rows });
            }
            else
            {
                return new JavaScriptSerializer().Serialize(new { success = false, message = "No data found" });
            }
        }
        catch (Exception ex)
        {
            return new JavaScriptSerializer().Serialize(new { success = false, message = ex.Message });
        }
    }

    [WebMethod]
    public static string SaveFormula(
    string formulaExpression,
    string genId,
    string schId,
    string billTypeId,
    string plantName,
    string billType
)
    {
        try
        {
            if (HttpContext.Current.Session["UserId"] == null)
            {
                return new JavaScriptSerializer().Serialize(new
                {
                    success = false,
                    message = "Session expired. Please login again."
                });
            }

            string addedBy = HttpContext.Current.Session["USERNAME"] != null
                ? HttpContext.Current.Session["USERNAME"].ToString()
                : "SYSTEM";

            string[] Param =
            {
            formulaExpression,
            genId,
            schId,
            billTypeId,
            plantName,
            billType,
            addedBy
        };

            string[] PName =
            {
            "@FORMULA",
            "@GID",
            "@SCH_ID",
            "@BILL_TYPE_ID",
            "@PLANTNAME",
            "@BILL_TYPE",
            "@ADDEDBY"
        };

            DataTable dt = SqlCmd.SelectDatakpcl(
                "SP_CHECK_FORMULAE",
                Param,
                PName,
                Param.Length
            );

            if (dt.Rows.Count > 0)
            {
                return new JavaScriptSerializer().Serialize(new
                {
                    success = false,
                    message = "Already Formula Exist for: " + plantName
                });
            }

            SqlCmd.ExecNonQuerykpcl(
                "SP_INSERT_FORMULA",
                Param,
                PName,
                Param.Length
            );

            return new JavaScriptSerializer().Serialize(new
            {
                success = true,
                message = "Formula saved successfully"
            });
        }
        catch (Exception ex)
        {
            return new JavaScriptSerializer().Serialize(new
            {
                success = false,
                message = ex.Message
            });
        }
    }



    [WebMethod]
    public static List<object> Get_Plants(string GenType, string Plant_CompType)
    {
        try
        {

            Param[0] = GenType;
            PName[0] = "@GID";

            Param[1] = Plant_CompType;
            PName[1] = "@BILL_TYPE_ID";

            Count = 2;

            DataTable dt = SqlCmd.SelectDatakpcl("SP_GET_PLANTNAME", Param, PName, Count);


            var list = new List<object>();
            foreach (DataRow row in dt.Rows)
            {
                list.Add(new
                {
                    PID = row["SCH_ID"].ToString(),
                    PLANTNAME = row["PLANTNAME"].ToString()
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
    public static List<object> Get_Plant_CompType(string GenType)
    {
        try
        {

            Param[0] = GenType;
            PName[0] = "@GID";

            Count = 1;


            DataTable dt = SqlCmd.SelectDatakpcl("SP_PLANT_COMP_TYPE", Param, PName, Count);

            var list = new List<object>();
            foreach (DataRow row in dt.Rows)
            {
                list.Add(new
                {
                    CPID = row["BILL_TYPE_ID"].ToString(),
                    CPLANTNAME = row["BILL_TYPE"].ToString()
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
    public static List<object> Get_FormulaData(string GID,string CompType)
    {
        try
        {
           
            Param[0] = GID.ToString();
            PName[0] = "@GID";

            Param[1] = CompType.ToString();
            PName[1] = "@CompType";

            DataTable dt = SqlCmd.SelectDatakpcl("SP_GET_FORMULA", Param, PName, 2);

            List<object> list = new List<object>();

            foreach (DataRow row in dt.Rows)
            {
                list.Add(new
                {
                    FID = row["FID"].ToString(),
                    GID = row["GID"].ToString(),
                    SCH_ID = row["SCH_ID"].ToString(),
                    BILL_TYPE_ID = row["BILL_TYPE_ID"].ToString(),
                    FORMULA = row["FORMULA"].ToString(),
                    PLANTNAME = row["PLANTNAME"].ToString(),
                    BILL_TYPE = row["BILL_TYPE"].ToString(),
                    ADDEDBY = row["ADDEDBY"].ToString(),
                    ADDEDON = row["ADDEDON"] == DBNull.Value
                                ? ""
                                : Convert.ToDateTime(row["ADDEDON"]).ToString("dd/MM/yyyy"),

                    REMARKS = row["REMARKS"].ToString()
                });
            }

            return list;
        }
        catch (Exception ex)
        {
            throw new Exception("Error fetching formula data: " + ex.Message);
        }
    }




    [WebMethod]
    public static string UpdateFormula(string FID, string formulaExpression, string genId, string schId, string billTypeId,
       string plantName, string billType,string Remarks)
    {
        try
        {
            Param[0] = FID;
            Param[1] = formulaExpression;
            Param[2] = genId;
            Param[3] = schId;
            Param[4] = billTypeId;
            Param[5] = plantName;
            Param[6] = billType;
            Param[7] = HttpContext.Current.Session["USERNAME"] != null ? HttpContext.Current.Session["USERNAME"].ToString() : "SYSTEM";
            Param[8] = Remarks;

            PName[0] = "@FID";
            PName[1] = "@FORMULA";
            PName[2] = "@GID";
            PName[3] = "@SCH_ID";
            PName[4] = "@BILL_TYPE_ID";
            PName[5] = "@PLANTNAME";
            PName[6] = "@BILL_TYPE";
            PName[7] = "@UPDATEDBY";
            PName[8] = "@REMARKS";


            Count = 9;


            int i = SqlCmd.ExecNonQuerykpcl("SP_UPDATE_FORMULA", Param, PName, Count);

            return JsonConvert.SerializeObject(new { success = true });
        }
        catch (Exception ex)
        {
            return JsonConvert.SerializeObject(new { success = false, message = ex.Message });
        }
    }


    [WebMethod]
    public static string GetLogData(string genId, string PlantId, string billTypeId)
    {
        try
        {
            Param[0] = genId;
            PName[0] = "@GID";


            Param[1] = PlantId;
            PName[1] = "@PID";


            Param[2] = billTypeId;
            PName[2] = "@BTYPE";

            Count = 3;

            DataTable dt = SqlCmd.SelectDatakpcl("SP_GET_LOGDATA_FORMULA", Param, PName, Count);

            var list = new System.Collections.Generic.List<System.Collections.Generic.Dictionary<string, object>>();
            foreach (DataRow row in dt.Rows)
            {
                var dict = new System.Collections.Generic.Dictionary<string, object>();
                foreach (DataColumn col in dt.Columns)
                {
                    dict[col.ColumnName] = row[col];
                }
                list.Add(dict);
            }

            var serializer = new JavaScriptSerializer();
            return serializer.Serialize(list);
        }
        catch (Exception ex)
        {
            return "[]";
        }
    }
}