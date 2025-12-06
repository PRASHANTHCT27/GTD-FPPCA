using ClosedXML.Excel;
using DocumentFormat.OpenXml.Bibliography;
using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.IO;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.Script.Services;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class KPCL_coal_fuelmanagement_Frm_FPPCA_Atual_PPC : System.Web.UI.Page
{

    static DataTable dt = new DataTable();
    static SqlCmd SqlCmd = new SqlCmd();
    static string[] Param = new string[30];
    static string[] PName = new string[30];

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            // Initial setup if needed
        }
    }

    [WebMethod]
    public static object GetPPCData(string escom, string year, string month)
    {
        try
        {
            DateTime selectedDate = DateTime.ParseExact(month, "MMM-yyyy", CultureInfo.InvariantCulture);
            string formattedMonth = selectedDate.ToString("yyyy-MM");

            string[] Param = new string[2];
            string[] PName = new string[2];

            Param[0] = formattedMonth;
            Param[1] = escom;
            PName[0] = "@YYYY_MM";
            PName[1] = "@ESCOM";

            DataTable spData = SqlCmd.SelectDatakpcl("SP_FPPCA_STATEMENT_V4", Param, PName, 2);

            if (spData != null && spData.Rows.Count > 0)
            {
                var groupedData = new Dictionary<string, List<Dictionary<string, object>>>();
                var sectionNames = new Dictionary<string, string>();

                foreach (DataRow row in spData.Rows)
                {
                    string sectionId = row["STATION_SECTION_ID"].ToString();
                    string sectionName = row["STATION_SECTION"].ToString();

                    if (!groupedData.ContainsKey(sectionId))
                        groupedData[sectionId] = new List<Dictionary<string, object>>();

                    if (!sectionNames.ContainsKey(sectionId))
                        sectionNames[sectionId] = sectionName;

                    // ✅ Safe Date conversion
                    string rcptDate = row["RCPTDATE"] == DBNull.Value ? "" :
                                      Convert.ToDateTime(row["RCPTDATE"]).ToString("yyyy-MM-dd");

                    string billDate = row["BILLDATE"] == DBNull.Value ? "" :
                                      Convert.ToDateTime(row["BILLDATE"]).ToString("yyyy-MM-dd");

                    var dataRow = new Dictionary<string, object>
                {
                    { "FPPCAID", row["FPPCAID"] },
                    { "Name of the Generating Station", row["GENSTN"] },
                    { "Capacity Charges Per Month", row["Capcity_Charges"] },
                    { "Variable Charges (Rs./unit)", row["Variable_Charges"] },
                    { "Capacity Charges for the Month", row["SCC"] },
                    { "Quantum of energy Purchased in the month", row["SNME"] },
                    { "Variable Charges1 (Rs./unit)", row["ECR"] },
                    { "Variable Charges (Rs.in Cr.)", row["SAMT"] },
                    { "Total Power Purchase cost paid for the month", "" },
                    { "Difference in power Purchase cost for the month", "" },
                    { "RCPTDATE", rcptDate },
                    { "BILLDATE", billDate },
                    { "NME", row["NME"] },
                    { "CC", row["CC"] },
                    { "PEC", row["PEC"] },
                    { "SEC", row["SEC"] },
                    { "RC", row["RC"] },
                    { "VAMT", row["VAMT"] },
                    { "PERC", row["RC"] },
                    { "ALLOCATED", row["ALLOCATED"] }
                };

                    groupedData[sectionId].Add(dataRow);
                }

                return new { HasData = true, Sections = groupedData, SectionNames = sectionNames };
            }
            else
            {
                return new { HasData = false };
            }
        }
        catch (Exception ex)
        {
            return new { HasData = false, Error = ex.Message };
        }
    }



    /* [WebMethod(EnableSession = true)]
     public static string SavePPCData(string escom, string year, string month, List<Dictionary<string, string>> data, string sectionId)
     {
         try
         {
            *//* if (data == null || data.Count == 0)
                 return "No data to save.";*//*

             // ✅ Convert Month format (e.g., "Jul-2025" → "2025-07-01")
             string formattedMonth = month;
             try
             {
                 DateTime parsedDate = DateTime.ParseExact(month, "MMM-yyyy", System.Globalization.CultureInfo.InvariantCulture);
                 formattedMonth = parsedDate.ToString("yyyy-MM-01");
             }
             catch { }

             // ✅ Delete existing data once (before inserting new)
             string firstFppcaId = data[0].ContainsKey("FPPCAID") ? data[0]["FPPCAID"] : "0";

             string[] delParam = new string[3];
             string[] delPName = new string[3];
             delParam[0] = formattedMonth;
             delParam[1] = sectionId;
             delParam[2] = firstFppcaId;

             delPName[0] = "@MONTH";
             delPName[1] = "@STATION_SECTION_ID";
             delPName[2] = "@FPPCAID";

             SqlCmd.ExecNonQuerykpcl("Delete_Actual_Power_Purchase_Cost", delParam, delPName, 3);

             // ✅ Now insert new rows
             foreach (var row in data)
             {
                 string fppcaId = row.ContainsKey("FPPCAID") ? row["FPPCAID"] : "0";

                 string capPerMonth = GetSafeValue(row, "Capacity Charges Per Month");
                 string varChargesPerUnit = GetSafeValue(row, "Variable Charges (Rs./unit)");
                 string capChargeForMonth = GetSafeValue(row, "Capacity Charges for the Month");
                 string qtyPurchased = GetSafeValue(row, "Quantum of energy Purchased in the month");
                 string varCharges1PerUnit = GetSafeValue(row, "Variable Charges1 (Rs./unit)");
                 string varChargesInCr = GetSafeValue(row, "Variable Charges (Rs.in Cr.)");
                 string totalPowerPurchaseCost = GetSafeValue(row, "Total Power Purchase cost paid for the month");
                 string diffPowerPurchaseCost = GetSafeValue(row, "Difference in power Purchase cost for the month");

                 string AddedBy = HttpContext.Current.Session["USERNAME"] != null
                     ? HttpContext.Current.Session["USERNAME"].ToString()
                     : "SYSTEM";

                 string[] Param = new string[13];
                 string[] PName = new string[13];

                 Param[0] = escom;
                 Param[1] = year;
                 Param[2] = formattedMonth;
                 Param[3] = sectionId;
                 Param[4] = fppcaId;
                 Param[5] = capPerMonth;
                 Param[6] = varChargesPerUnit;
                 Param[7] = capChargeForMonth;
                 Param[8] = qtyPurchased;
                 Param[9] = varCharges1PerUnit;
                 Param[10] = varChargesInCr;
                 Param[11] = totalPowerPurchaseCost;
                 Param[12] = diffPowerPurchaseCost;
                 Param[13] = AddedBy;


                 PName[0] = "@ESCOM";
                 PName[1] = "@FYEAR";
                 PName[2] = "@MONTH";
                 PName[3] = "@STATION_SECTION_ID";
                 PName[4] = "@FPPCAID";
                 PName[5] = "@CAP_PER_MONTH";
                 PName[6] = "@VAR_CHG_PER_UNIT";
                 PName[7] = "@CAP_CHG_FOR_MONTH";
                 PName[8] = "@QTY_PURCHASED";
                 PName[9] = "@VAR_CHG_PUNIT";
                 PName[10] = "@VAR_CHG_IN_CR";
                 PName[11] = "@Total_Power_Purchase_Cost";
                 PName[12] = "@Difference_Power_Purchase_Cost";
                 PName[13] = "@ADDED_BY";

                 SqlCmd.ExecNonQuerykpcl("SP_Insert_Actual_Power_Purchase_Cost", Param, PName, Param.Length);
             }

             return "✅ Data saved successfully.";
         }
         catch (Exception ex)
         {
             return "❌ Error: " + ex.Message;
         }
     }*/


    [WebMethod(EnableSession = true)]
    public static string SavePPCData(string escom, string year, string month, List<Dictionary<string, string>> data, string sectionId,string type)
    {
        try
        {
            // Convert month format (Jul-2025 → 2025-07-01)
            string formattedMonth = month;
            try
            {
                DateTime parsedDate = DateTime.ParseExact(month, "MMM-yyyy",
                    System.Globalization.CultureInfo.InvariantCulture);
                formattedMonth = parsedDate.ToString("yyyy-MM-01");
            }
            catch { }

            // Delete existing data once
            string firstFppcaId = data[0].ContainsKey("FPPCAID") ? data[0]["FPPCAID"] : "0";

            string[] delParam = new string[4];
            string[] delPName = new string[4];

            delParam[0] = formattedMonth;
            delParam[1] = sectionId;
            delParam[2] = firstFppcaId;
            delParam[3] = type;

            delPName[0] = "@MONTH";
            delPName[1] = "@STATION_SECTION_ID";
            delPName[2] = "@FPPCAID";
            delPName[3] = "@type";

            SqlCmd.ExecNonQuerykpcl("Delete_Actual_Power_Purchase_Cost", delParam, delPName, 4);

            // Insert rows
            foreach (var row in data)
            {
                string fppcaId = row.ContainsKey("FPPCAID") ? row["FPPCAID"] : "0";

                string capPerMonth = GetSafeValue(row, "Capacity Charges Per Month");
                string varChargesPerUnit = GetSafeValue(row, "Variable Charges (Rs./unit)");
                string capChargeForMonth = GetSafeValue(row, "Capacity Charges for the Month");
                string qtyPurchased = GetSafeValue(row, "Quantum of energy Purchased in the month");
                string varCharges1PerUnit = GetSafeValue(row, "Variable Charges1 (Rs./unit)");
                string varChargesInCr = GetSafeValue(row, "Variable Charges (Rs.in Cr.)");
                string totalPowerPurchaseCost = GetSafeValue(row, "Total Power Purchase cost paid for the month");
                string diffPowerPurchaseCost = GetSafeValue(row, "Difference in power Purchase cost for the month");

                // Hidden columns
                string rcptDate = GetSafeValue(row, "RCPTDATE");
                string billDate = GetSafeValue(row, "BILLDATE");
                string nme = GetSafeValue(row, "NME");
                string cc = GetSafeValue(row, "CC");
                string pec = GetSafeValue(row, "PEC");
                string sec = GetSafeValue(row, "SEC");
                string rc = GetSafeValue(row, "RC");
                string vamt = GetSafeValue(row, "VAMT");
                string perc = GetSafeValue(row, "PERC");
                string allocated = GetSafeValue(row, "ALLOCATED");

                // Convert date strings to yyyy-MM-dd or NULL
                rcptDate = NormalizeDate(rcptDate);
                billDate = NormalizeDate(billDate);

                string AddedBy = HttpContext.Current.Session["USERNAME"] != null
                    ? HttpContext.Current.Session["USERNAME"].ToString()
                    : "SYSTEM";

                 string[] Param = new string[25];
                 string[] PName = new string[25];

                Param[0] = escom;
                Param[1] = year;
                Param[2] = formattedMonth;
                Param[3] = sectionId;
                Param[4] = fppcaId;
                Param[5] = capPerMonth;
                Param[6] = varChargesPerUnit;
                Param[7] = capChargeForMonth;
                Param[8] = qtyPurchased;
                Param[9] = varCharges1PerUnit;
                Param[10] = varChargesInCr;
                Param[11] = totalPowerPurchaseCost;
                Param[12] = diffPowerPurchaseCost;
                Param[13] = AddedBy;

                Param[14] = formattedMonth;
               Param[15] = string.IsNullOrWhiteSpace(billDate) ? "" : billDate; 
                //string.IsNullOrWhiteSpace(billDate) ? "NULL" : billDate;
                Param[16] = nme;
                Param[17] = cc;
                Param[18] = pec;
                Param[19] = sec;
                Param[20] = rc;
                Param[21] = vamt;
                Param[22] = perc;
                Param[23] = allocated;
                Param[24] = type;

                PName[0] = "@ESCOM";
                PName[1] = "@FYEAR";
                PName[2] = "@MONTH";
                PName[3] = "@STATION_SECTION_ID";
                PName[4] = "@FPPCAID";
                PName[5] = "@CAP_PER_MONTH";
                PName[6] = "@VAR_CHG_PER_UNIT";
                PName[7] = "@CAP_CHG_FOR_MONTH";
                PName[8] = "@QTY_PURCHASED";
                PName[9] = "@VAR_CHG_PUNIT";
                PName[10] = "@VAR_CHG_IN_CR";
                PName[11] = "@Total_Power_Purchase_Cost";
                PName[12] = "@Difference_Power_Purchase_Cost";
                PName[13] = "@ADDED_BY";
                PName[14] = "@RCPTDATE";
                PName[15] = "@BILLDATE";
                PName[16] = "@NME";
                PName[17] = "@CC";
                PName[18] = "@PEC";
                PName[19] = "@SEC";
                PName[20] = "@RC";
                PName[21] = "@VAMT";
                PName[22] = "@PERC";
                PName[23] = "@ALLOCATED";
                PName[24] = "@type";

                SqlCmd.ExecNonQuerykpcl("SP_Insert_Actual_Power_Purchase_Cost",
                    Param, PName, Param.Length);
            }
           
            return "✅ Data saved successfully.";
        }
        catch (Exception ex)
        {
            return "❌ Error: " + ex.Message;
        }
    }

    // Converts blank/invalid/NULL → null else yyyy-MM-dd
    public static string NormalizeDate(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
            return null;

        value = value.Trim();

        if (value.Equals("NULL", StringComparison.OrdinalIgnoreCase))
            return null;

        DateTime dt;
        if (DateTime.TryParse(value, out dt))
            return dt.ToString("yyyy-MM-dd");

        return null;
    }


    /*// ✅ Converts any date string to yyyy-MM-dd, fallback = 0001-01-01
    private static string NormalizeDate(string dateStr)
    {
        if (string.IsNullOrWhiteSpace(dateStr)) return "0001-01-01";

        DateTime dt;
        string[] formats = { "yyyy-MM-dd", "dd-MM-yyyy", "MM/dd/yyyy", "dd/MM/yyyy HH:mm:ss", "yyyy-MM-dd HH:mm:ss", "MM-dd-yyyy HH:mm:ss" };

        if (DateTime.TryParseExact(dateStr, formats, System.Globalization.CultureInfo.InvariantCulture,
            System.Globalization.DateTimeStyles.None, out dt))
        {
            return dt.ToString("yyyy-MM-dd");
        }

        // Try general parse as fallback
        if (DateTime.TryParse(dateStr, out dt))
            return dt.ToString("yyyy-MM-dd");

        return "0001-01-01"; // fallback invalid date
    }*/

    // ✅ Helper remains the same
    private static string GetSafeValue(Dictionary<string, string> row, string key)
{
    if (row.ContainsKey(key))
    {
        var value = row[key];
        return string.IsNullOrWhiteSpace(value) ? "0" : value;
    }
    return "0";
}


/*
    // ✅ Helper to handle null or blank values
    private static string GetSafeValue(Dictionary<string, string> row, string key)
    {
        if (row.ContainsKey(key))
        {
            var value = row[key];
            return string.IsNullOrWhiteSpace(value) ? "0" : value;
        }
        return "0";
    }
*/


    [WebMethod]
    public static List<object> GetEscoms()
    {
        try
        {
            DataTable dt = SqlCmd.SelectQuerykpcl("SP_GET_ESCOMS");

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
    private static List<Dictionary<string, object>> DataTableToList(DataTable dt)
    {
        var rows = new List<Dictionary<string, object>>();
        foreach (DataRow dr in dt.Rows)
        {
            var row = new Dictionary<string, object>();
            foreach (DataColumn col in dt.Columns)
                row[col.ColumnName] = dr[col];
            rows.Add(row);
        }
        return rows;
    }


    [WebMethod]
    public static object SaveGrandTotalSection12(Dictionary<string, object> grandTotal,string Month,string Escom,string type)
    {
        try
        {

            string formattedMonth = Month;
            try
            {
                DateTime parsedDate = DateTime.ParseExact(Month, "MMM-yyyy",
                    System.Globalization.CultureInfo.InvariantCulture);
                formattedMonth = parsedDate.ToString("yyyy-MM-01");
            }
            catch { }

            if (grandTotal == null || grandTotal.Count == 0)
            {
                return new { status = false, message = "Grand Total object is empty" };
            }

            // Extract values safely
            decimal capPerMonth = GetValue(grandTotal, "Capacity Charges Per Month");
            decimal capForMonth = GetValue(grandTotal, "Capacity Charges for the Month");
            decimal quantum = GetValue(grandTotal, "Quantum of energy Purchased in the month");
            decimal variableCr = GetValue(grandTotal, "Variable Charges (Rs.in Cr.)");
            decimal totalPpc = GetValue(grandTotal, "Total Power Purchase cost paid for the month");
            decimal diffPpc = GetValue(grandTotal, "Difference in power Purchase cost for the month");

            string[] DParam = new string[4];
            string[] DPName = new string[4];

            DParam[0] = Escom.ToString();
            DParam[1] = formattedMonth.ToString();
            DParam[2] = type.ToString();

            DPName[0] = "@ESCOMS";
            DPName[1] = "@RDATE";
            DPName[2] = "@TYPE";

            int i= SqlCmd.ExecNonQuerykpcl("SP_DELETE_FPPCA_GRANDTOTAL", DParam, DPName, 3);

            Param[0] = capPerMonth.ToString();
            Param[1] = capForMonth.ToString();
            Param[2] = quantum.ToString();
            Param[3] = variableCr.ToString();
            Param[4] = totalPpc.ToString();
            Param[5] = diffPpc.ToString();
            Param[6] = Escom.ToString();
            Param[7] = formattedMonth.ToString();
            Param[8] = type.ToString();


            PName[0] = "@Capacity_Charges_Per_Month";
            PName[1] = "@Capacity_Charges_for_Month";
            PName[2] = "@Quantum_Energy";
            PName[3] = "@Variable_Charges_In_Cr";
            PName[4] = "@Total_Power_Purchase_Cost";
            PName[5] = "@Difference_PPC";
            PName[6] = "@ESCOMS";
            PName[7] = "@RDATE";
            PName[8] = "@TYPE";
            // Execute SP
            DataTable result = SqlCmd.SelectDatakpcl(
                "SP_SAVE_FPPCA_GRANDTOTA", Param, PName, 9);

            return new
            {
                status = true,
                message = "Grand Total Saved Successfully!",
                data = result
            };
        }
        catch (Exception ex)
        {
            return new { status = false, message = ex.Message };
        }
    }


    private static decimal GetValue(Dictionary<string, object> dict, string key)
    {
        if (!dict.ContainsKey(key) || dict[key] == null) return 0;

        decimal val;
        decimal.TryParse(dict[key].ToString(), out val);
        return val;
    }

}

