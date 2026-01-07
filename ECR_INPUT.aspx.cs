using DocumentFormat.OpenXml.Bibliography;
using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.Linq;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class CGS_ECR_INPUT : System.Web.UI.Page
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
    static int FormId = 105;

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
    public static string getLoginUserId()
    {
        try
        {
            return userId = HttpContext.Current.Session["UserId"].ToString();
        }
        catch (Exception ex)
        {

        }
        return null;
    }

    [System.Web.Services.WebMethod]
    public static List<int> GetAllowedUserIds()
    {
        List<int> allowed = new List<int>();

        Param[0] = FormId.ToString();
        PName[0] = "@FORMID";

        DataTable dt = SqlCmd.SelectDatakpcl("SP_GET_FORM_DETAILS", Param, PName, 1);

        foreach (DataRow row in dt.Rows)
        {
            if (!string.IsNullOrEmpty(row["PWRITE"].ToString()))
            {
                allowed.AddRange(
                    row["PWRITE"].ToString()
                       .Split(',')
                       .Select(x => Convert.ToInt32(x.Trim()))
                );
            }
        }

        return allowed;
    }

    [WebMethod]
    public static string GetFormulaForPlant(string plantId, string billTypeId)
    {
        try
        {
            Param[0] = plantId;
            PName[0] = "@SCH_ID";

            Param[1] = billTypeId;
            PName[1] = "@BILL_TYPE_ID";

            DataTable dtFormula = SqlCmd.SelectDatakpcl("SP_GET_PLANT_FORMULA", Param, PName, 2);

            if (dtFormula.Rows.Count == 0)
            {
                return new JavaScriptSerializer().Serialize(new
                {
                    success = false,
                    message = "No formula found for selected plant"
                });
            }

            string formula = dtFormula.Rows[0]["FORMULA"].ToString();

            DataTable dtTerms = SqlCmd.SelectDatakpcl("SP_GET_THERMAL_TERM", null, null, 0);

            var terms = new Dictionary<string, object>();

            foreach (DataRow row in dtTerms.Rows)
            {
                string termCode = row["TERM_NAME"].ToString();

                terms[termCode] = new
                {
                    TID = row["TID"].ToString(),
                    DisplayName = row["TERM_DESCRIPTION"].ToString(),
                    CurrentValue = ""
                };
            }

            return new JavaScriptSerializer().Serialize(new
            {
                success = true,
                formula = formula,
                terms = terms
            });
        }
        catch (Exception ex)
        {
            return new JavaScriptSerializer().Serialize(new
            {
                success = false,
                message = "Error loading formula: " + ex.Message
            });
        }
    }


    public class TermData
    {
        public string termId { get; set; }
        public string value { get; set; }
    }

    [WebMethod]
    public static string SaveECRData(string plantId, string billTypeId, string monthYear, string formula,
        Dictionary<string, TermData> termValues, string calculatedValue)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(plantId) ||
                string.IsNullOrWhiteSpace(billTypeId) ||
                string.IsNullOrWhiteSpace(monthYear) ||
                termValues == null || termValues.Count == 0)
            {
                return new JavaScriptSerializer().Serialize(new
                {
                    success = false,
                    message = "Invalid input parameters."
                });
            }

            if (HttpContext.Current.Session["UserId"] == null)
            {
                return new JavaScriptSerializer().Serialize(new
                {
                    success = false,
                    message = "Session expired. Please login again."
                });
            }

            string userName = "SYSTEM";
            if (HttpContext.Current.Session["USERNAME"] != null)
            {
                userName = HttpContext.Current.Session["USERNAME"].ToString();
            }

            DateTime monthDate;
            if (!DateTime.TryParseExact(monthYear, "MMM-yyyy", CultureInfo.InvariantCulture, DateTimeStyles.None, out monthDate))
            {
                return new JavaScriptSerializer().Serialize(new
                {
                    success = false,
                    message = "Invalid date format. Expected format: MMM-yyyy (e.g., Jan-2025)"
                });
            }

            string formattedDate = monthDate.ToString("yyyy-MM-dd");

            string fyYear;
            if (monthDate.Month >= 4)
            {
                fyYear = monthDate.Year.ToString() + "-" + (monthDate.Year + 1).ToString();
            }
            else
            {
                fyYear = (monthDate.Year - 1).ToString() + "-" + monthDate.Year.ToString();
            }

            string[] chkParam = { plantId, billTypeId, formattedDate };
            string[] chkPName = { "@SCH_ID", "@BILLTYPE_ID", "@MONTH_YEAR" };

            DataTable dtCheck = SqlCmd.SelectDatakpcl("SP_CHECK_ECR_DATA_EXISTS", chkParam, chkPName, chkParam.Length);

            if (dtCheck != null && dtCheck.Rows.Count > 0)
            {
                return new JavaScriptSerializer().Serialize(new
                {
                    success = false,
                    message = "ECR Data Already Exists For: " + monthYear
                });
            }

            int insertCount = 0;
            List<string> errors = new List<string>();

            foreach (var item in termValues)
            {
                try
                {
                    string termCode = item.Key;
                    if (!string.IsNullOrWhiteSpace(termCode))
                    {
                        termCode = termCode.Trim();
                    }

                    if (string.IsNullOrWhiteSpace(termCode))
                    {
                        errors.Add("Empty term code found");
                        continue;
                    }

                    string termId = null;
                    string termValueStr = null;

                    if (item.Value != null)
                    {
                        termId = item.Value.termId;
                        termValueStr = item.Value.value;

                        if (!string.IsNullOrWhiteSpace(termId))
                        {
                            termId = termId.Trim();
                        }
                    }

                    if (string.IsNullOrWhiteSpace(termId))
                    {
                        errors.Add("Missing Term ID for '" + termCode + "'");
                        continue;
                    }

                    double termValue = 0;
                    if (!string.IsNullOrWhiteSpace(termValueStr))
                    {
                        if (!double.TryParse(termValueStr, NumberStyles.Any, CultureInfo.InvariantCulture, out termValue))
                        {
                            errors.Add("Invalid value for term '" + termCode + "': " + termValueStr);
                            continue;
                        }
                    }


                    string[] insertParam = new string[11];
                    string[] insertPName = new string[11];

                    insertParam[0] = formattedDate;
                    insertPName[0] = "@MONTH_YEAR";

                    insertParam[1] = fyYear;
                    insertPName[1] = "@FY_YEAR";

                    insertParam[2] = plantId;
                    insertPName[2] = "@SCH_ID";

                    insertParam[3] = termId;
                    insertPName[3] = "@TERM_ID";

                    insertParam[4] = termCode;
                    insertPName[4] = "@TERM_HEAD";

                    insertParam[5] = termValue.ToString(CultureInfo.InvariantCulture);
                    insertPName[5] = "@TERM_VALUE";

                    insertParam[6] = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                    insertPName[6] = "@ADDEDON";

                    insertParam[7] = userName;
                    insertPName[7] = "@ADDEDBY";

                    insertParam[8] = calculatedValue;
                    insertPName[8] = "@ECR";

                    insertParam[9] = "100001";
                    insertPName[9] = "@ESCOMID";

                    insertParam[10] = billTypeId;
                    insertPName[10] = "@BILLTYPE_ID";

                    SqlCmd.ExecNonQuerykpcl("SP_INSERT_ECR_TRANSACTION", insertParam, insertPName, insertParam.Length);
                    insertCount++;
                }
                catch (Exception innerEx)
                {
                    errors.Add("Error processing term '" + item.Key + "': " + innerEx.Message);
                }
            }

            if (insertCount == 0)
            {
                string errorMsg = "No records were inserted.";
                if (errors.Count > 0)
                {
                    errorMsg = errorMsg + " Errors: " + string.Join("; ", errors);
                }

                return new JavaScriptSerializer().Serialize(new
                {
                    success = false,
                    message = errorMsg,
                    recordsInserted = 0,
                    warnings = errors
                });
            }

            string responseMessage = "ECR data saved successfully! (" + insertCount.ToString() + " records inserted)";
            if (errors.Count > 0)
            {
                responseMessage = responseMessage + " | Warnings: " + string.Join("; ", errors);
            }

            return new JavaScriptSerializer().Serialize(new
            {
                success = true,
                message = responseMessage,
                recordsInserted = insertCount,
                warnings = errors
            });
        }
        catch (Exception ex)
        {
            return new JavaScriptSerializer().Serialize(new
            {
                success = false,
                message = "Error saving ECR data: " + ex.Message
            });
        }
    }



    [WebMethod]
    public static string GetECRData(string plantId, string billTypeId, string monthYear)
    {
        try
        {
            DateTime monthDate = DateTime.ParseExact(
                monthYear,
                "MMM-yyyy",
                CultureInfo.InvariantCulture
            );

            string formattedDate = monthDate.ToString("yyyy-MM-01", CultureInfo.InvariantCulture);

            Param[0] = formattedDate;
            PName[0] = "@MONTH_YEAR";

            Param[1] = plantId;
            PName[1] = "@SCH_ID";

            DataTable dt = SqlCmd.SelectDatakpcl("SP_GET_ECR_DATA",Param,PName,2);

            if (dt.Rows.Count == 0)
            {
                return new JavaScriptSerializer().Serialize(new
                {
                    success = false,
                    message = "No data found"
                });
            }
            List<object> ecrList = new List<object>();

            foreach (DataRow row in dt.Rows)
            {
                ecrList.Add(new
                {
                    ecr_id = row["ID"].ToString(),
                    month_year = Convert.ToDateTime(row["MONTH_YEAR"]).ToString("MMM-yyyy"),

                   fy_year = row["FY_YEAR"].ToString(),
                    sch_id = row["SCH_ID"].ToString(),
                    term_id = row["TERM_ID"].ToString(),
                    term_head = row["TERM_HEAD"].ToString(),
                    term_value = row["TERM_VALUE"].ToString(),
                    created_date = Convert.ToDateTime(row["ADDEDON"]).ToString("yyyy-MM-dd"),
                    added_by = row["ADDEDBY"].ToString(),
                    escom_id = row["ESCOMID"].ToString()
                });
            }

            return new JavaScriptSerializer().Serialize(new
            {
                success = true,
                data = ecrList   
            });
        }
        catch (Exception ex)
        {
            return new JavaScriptSerializer().Serialize(new
            {
                success = false,
                message = "Error retrieving data: " + ex.Message
            });
        }
    }



    [WebMethod]
    public static string UpdateECRData(string Month,string ecrId,string termId,string TermValue
)
    {
        try
        {
            DateTime monthDate = DateTime.ParseExact(Month,"MMM-yyyy",CultureInfo.InvariantCulture);

            string formattedDate = monthDate.ToString("yyyy-MM-01", CultureInfo.InvariantCulture);

            if (HttpContext.Current.Session["UserId"] == null)
            {
                return new JavaScriptSerializer().Serialize(new
                {
                    success = false,
                    message = "Session expired. Please login again."
                });
            }

            string userId = HttpContext.Current.Session["UserId"].ToString();
            string modifiedBy = HttpContext.Current.Session["USERNAME"] != null
                ? HttpContext.Current.Session["USERNAME"].ToString()
                : "SYSTEM";


            Param[0] = formattedDate;
            PName[0] = "@MONTH_YEAR";

            Param[1] = ecrId;
            PName[1] = "@ECR_ID";

            Param[2] = termId;
            PName[2] = "@TERM_ID";

            Param[3] = TermValue;
            PName[3] = "@TERM_VALUE";

            Param[4] = modifiedBy;
            PName[4] = "@MODIFIED_BY";

           int i= SqlCmd.ExecNonQuerykpcl("SP_UPDATE_ECR_DATA",Param,PName,5);

            return new JavaScriptSerializer().Serialize(new
            {
                success = true,
                message = "ECR value updated successfully"
            });
        }
        catch (Exception ex)
        {
            return new JavaScriptSerializer().Serialize(new
            {
                success = false,
                message = "Error updating ECR: " + ex.Message
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
            throw new Exception("Error fetching plant data: " + ex.Message);
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
            throw new Exception("Error fetching bill type data: " + ex.Message);
        }
    }


    [WebMethod]
    public static string GetLogData(string monthYear, string plantId, string billTypeId)
    {
        try
        {
            DateTime monthDate = DateTime.ParseExact(monthYear,"MMM-yyyy",CultureInfo.InvariantCulture);

            string formattedDate = monthDate.ToString("yyyy-MM-01", CultureInfo.InvariantCulture);

            Param[0] = formattedDate;
            PName[0] = "@MONTH_YEAR";


            Param[1] = plantId;
            PName[1] = "@SCH_ID";


            Param[2] = billTypeId;
            PName[2] = "@BTYPE";

            Count = 3;

            DataTable dt = SqlCmd.SelectDatakpcl("SP_GET_LOG_TRANSACTION_DATA", Param, PName, Count);

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