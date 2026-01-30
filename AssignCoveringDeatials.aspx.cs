using DocumentFormat.OpenXml.Spreadsheet;
using iTextSharp.text;
using iTextSharp.text.pdf;
using Org.BouncyCastle.Crypto.Modes;
using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Threading;
using System.Web;
using System.Web.Configuration;
using System.Web.Script.Serialization;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;
using Font = iTextSharp.text.Font;

public partial class AssignCoveringDeatials : System.Web.UI.Page
{
    static SqlCmd SqlCmd = new SqlCmd();
    static string[] Param = new string[50];
    static string[] PName = new string[50];
    static int Count = 0;
    static alertmsg msg = new alertmsg();
    static DataTable dt;
    static string Drive;
    static string filename;
    static string IPP_ID = "";
    static string empDesignation = "", userName = "", FirmName = "";
    static string ESCOM = "";
    static int rolno = 0;
    static string userid = "";

    protected void Page_Load(object sender, EventArgs e)
    {
        if (HttpContext.Current.Session["UserId"] == null)
        {
            Response.Redirect("/Login.aspx");
        }
        else
        {
            System.Web.HttpContext.Current.Session["Path"] = "";
            userName = HttpContext.Current.Session["UserName"].ToString();
            userid = HttpContext.Current.Session["UserId"].ToString();
           // userid = "5";
            // rolno = Convert.ToInt32(HttpContext.Current.Session["ROLE_ID"]).ToString();
            ESCOM = HttpContext.Current.Session["ESCOM_NAME"].ToString();
            if (!IsPostBack)
            {

            }
        }

    }
    /* protected void Page_Load(object sender, EventArgs e)
     {


         *//*try
         {
             if (string.IsNullOrEmpty(Session["KPC_NAME"] as string))
             {
                 *//*Response.Redirect("/templates/login/LoginMain1.aspx");*//*
                 Response.Redirect("/templates/login/LoginMain1.aspx", true);

             }
             else
             {
                 userName = Session["KPC_NAME"].ToString();
                 rolno = Convert.ToInt32(Session["KPC_ROLE"]);
                 ESCOM = Session["KPC_ESCOM"].ToString();
             }
             if (!IsPostBack)
             {
                 rolno = Convert.ToInt32(Session["KPC_ROLE"]);
                 //getBankDetails();
                 *//*FetchDataForGenerateAt();*//*


             }
         }
         catch (Exception Ex)
         {


         }*//*

     }*/

    [WebMethod]
    public static object SaveCoverLetterDetails(string letterNo, string letterDate, List<Dictionary<string, object>> beneficiaries, string Month)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(letterNo))
            {
                return new { success = false, message = "Enter the Letter No" };
            }

            if (string.IsNullOrWhiteSpace(letterDate))
            {
                return new { success = false, message = "Enter Letter Date" };
            }

            if (string.IsNullOrWhiteSpace(Month))
            {
                return new { success = false, message = "Select Month" };
            }

            DateTime dtLetterD = DateTime.ParseExact(letterDate, "dd-MM-yyyy",
                System.Globalization.CultureInfo.InvariantCulture);

            DateTime selectedDate;
            bool isValidDate = DateTime.TryParseExact(
                Month,
                "MMM-yyyy",
                System.Globalization.CultureInfo.InvariantCulture,
                System.Globalization.DateTimeStyles.None,
                out selectedDate);

            if (!isValidDate)
            {
                return new { success = false, message = "Invalid Month-Year format" };
            }

            string Frommonthyer, Tomontyear;
            if (selectedDate.Month >= 4)
            {
                Frommonthyer = "04" + selectedDate.Year.ToString();
                Tomontyear = "03" + (selectedDate.Year + 1).ToString();
            }
            else
            {
                Frommonthyer = "04" + (selectedDate.Year - 1).ToString();
                Tomontyear = "03" + selectedDate.Year.ToString();
            }

            string escomValue = HttpContext.Current.Session["ESCOM_NAME"].ToString() ?? "";

            SqlCmd SqlCmd = new SqlCmd();

            string[] Param = new string[4];
            string[] PName = new string[4];

            Param[0] = letterNo;
            Param[1] = escomValue;
            Param[2] = Frommonthyer;
            Param[3] = Tomontyear;

            PName[0] = "@LETERNO";
            PName[1] = "@ESCOM";
            PName[2] = "@FROMMONTHYEAR";
            PName[3] = "@TOMONTHYEAR";

            DataTable CheckLeterNo = SqlCmd.SelectData("SP_CHECKLETERNO_Q1", Param, PName, 4);

            if (CheckLeterNo.Rows.Count > 0 && CheckLeterNo.Rows[0]["ExistsFlag"].ToString() == "1")
            {
                return new { success = false, message = "Letter No already exists!" };
            }

            if (beneficiaries == null || beneficiaries.Count == 0)
            {
                return new { success = false, message = "Please select at least one beneficiary." };
            }

            int count = 0;

            foreach (var row in beneficiaries)
            {
                string id = row["BT_SLNO"].ToString();

                string[] Param2 = new string[3];
                string[] PName2 = new string[3];

                Param2[0] = id;
                PName2[0] = "@ID";

                Param2[1] = letterNo;
                PName2[1] = "@LETTERNO";

                Param2[2] = dtLetterD.ToString("yyyy-MM-dd");
                PName2[2] = "@LETTERDATE";

                SqlCmd.ExecNonQuery("SP_SAVELETTERDETAILS_Q1", Param2, PName2, 3);
                count++;
            }

            return new { success = true, message = "Saved successfully!", total = count };
        }
        catch (Exception ex)
        {
            return new { success = false, message = ex.Message };
        }
    }


    public class ChequeDto
    {
        public string RECEIPT_NO { get; set; }
        public string ESCOMS { get; set; }   
        public string BT_SLNO { get; set; }  
    }

    [WebMethod]
    public static object RemoveCoveringLetters(List<ChequeDto> cheques)
    {
        try
        {
            if (cheques == null || cheques.Count == 0)
            {
                return new { success = false, message = "No records selected." };
            }

            int deletedCount = 0;

            string escomValue = HttpContext.Current.Session["ESCOM_NAME"].ToString() ?? "";

            foreach (var item in cheques)
            {
                string[] Param = new string[2];
                string[] PName = new string[2];

                Param[0] = item.RECEIPT_NO;
                PName[0] = "@RECEIPT_NO";

                Param[1] = escomValue;
                PName[1] = "@ESCOMS";

                int result = SqlCmd.ExecNonQuery("SP_LETTER_DETAILS_Q4", Param, PName, 2);

                if (result > 0)
                {
                    deletedCount++;
                }
            }

            if (deletedCount > 0)
            {
                return new
                {
                    success = true,
                    message = deletedCount + " record(s) removed successfully."
                };
            }
            else
            {
                return new { success = false, message = "No records removed." };
            }
        }
        catch (Exception ex)
        {
            return new { success = false, message = ex.Message };
        }
    }



    [WebMethod]
    public static object GeneratePDF(string receiptNo)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(receiptNo))
            {
                return new { success = false, message = "Receipt No is required." };
            }
            string comName = "", logoPath = "";

            string ESCOM = HttpContext.Current.Session["ESCOM_NAME"].ToString() ?? "";
            if (string.IsNullOrWhiteSpace(ESCOM))
            {
                return new { success = false, message = "ESCOM session is missing." };
            }

            switch (ESCOM)
            {
                case "BESCOM":
                    comName = "BANGALORE ELECTRICITY SUPPLY COMPANY LTD.";
                    logoPath = "https://kptclgtd.com/assets/images/BESCOMLOGO.png";
                    break;
                case "CESC":
                    comName = "CHAMUNDESHWARI ELECTRICITY SUPPLY CORPORATION LIMITED";
                    logoPath = "https://kptclgtd.com/assets/images/cesc1.png";
                    break;
                case "MESCOM":
                    comName = "MANGALORE ELECTRICITY SUPPLY COMPANY LIMITED";
                    logoPath = "https://kptclgtd.com/assets/images/MESCOMLOGO.png";
                    break;
                case "HESCOM":
                    comName = "HUBLI ELECTRICITY SUPPLY COMPANY LIMITED";
                    logoPath = "https://kptclgtd.com/assets/images/HESCOMLOGO.JPg";
                    break;
                case "GESCOM":
                    comName = "GULBARGA ELECTRICITY SUPPLY COMPANY LIMITED";
                    logoPath = "https://kptclgtd.com/assets/images/GESCOMLOGO.png";
                    break;
            }


          /*  if (!File.Exists(logoPath))
            {
                return new { success = false, message = "Logo file not found: " + logoPath };
            }*/
            /* string ESCOM = HttpContext.Current.Session["ESCOM_NAME"].ToString() ?? "";

             string comName = "", logoPath = "";

             if (ESCOM == "BESCOM")
             {
                 comName = "BANGALORE ELECTRICITY SUPPLY COMPANY LTD.";
                 //logoPath = HttpContext.Current.Server.MapPath("~/assets/images/BESCOM.png");
             }
             else if (ESCOM == "CESC")
             {
                 comName = "CHAMUNDESHWARI ELECTRICITY SUPPLY CARPORATION LIMITED";
                // logoPath = HttpContext.Current.Server.MapPath("~/assets/images/cesc1.png");
             }
             else if (ESCOM == "MESCOM")
             {
                 comName = "MANGALORE ELECTRICITY SUPPLY CARPORATION LIMITED";
                // logoPath = HttpContext.Current.Server.MapPath("~/assets/images/mescomdownload.jpg");
             }
             else if (ESCOM == "HESCOM")
             {
                 comName = "HUBLI ELECTRICITY SUPPLY COMPANY LIMITED";
                 //logoPath = HttpContext.Current.Server.MapPath("~/assets/images/HESCOM.jpg");
             }
             else if (ESCOM == "GESCOM")
             {
                 comName = "GULBARGA ELECTRICITY SUPPLY COMPANY LIMITED";
                // logoPath = HttpContext.Current.Server.MapPath("~/assets/images/GESCOM.jpg");
             }
 */
            Document document = new Document(PageSize.A4, 30f, 30f, 30f, 30f);
            using (var memoryStream = new System.IO.MemoryStream())
            {
                PdfWriter writer = PdfWriter.GetInstance(document, memoryStream);
                document.Open();

                Font headerFont = FontFactory.GetFont(FontFactory.TIMES_ROMAN, 12f, Font.BOLD);
                Font normalFont = FontFactory.GetFont(FontFactory.TIMES_ROMAN, 10f);
                Font smallFont = FontFactory.GetFont(FontFactory.TIMES_ROMAN, 9f);

                PdfPTable headerTable = new PdfPTable(3);
                headerTable.WidthPercentage = 100;
                headerTable.SetWidths(new float[] { 15f, 70f, 15f });

                Paragraph headingPara = new Paragraph();
                Chunk line1 = new Chunk(comName, headerFont);
                line1.SetUnderline(0.5f, -1.5f);
                headingPara.Add(line1);
                headingPara.Alignment = Element.ALIGN_CENTER;
                document.Add(headingPara);

                document.Add(headerTable);

                Paragraph heading2 = new Paragraph("(Wholly Owned Government of Karnataka Undertaking)", smallFont);
                heading2.Alignment = Element.ALIGN_CENTER;
                heading2.SpacingAfter = 5f;
                document.Add(heading2);

                PdfPTable headerTable1 = new PdfPTable(1);
                headerTable1.WidthPercentage = 100;
                headerTable1.SetWidths(new float[] { 50f });

                PdfPCell docNoCell = new PdfPCell(new Phrase("No: " + ESCOM, normalFont));
                docNoCell.Border = PdfPCell.NO_BORDER;
                docNoCell.HorizontalAlignment = Element.ALIGN_LEFT;
                docNoCell.Padding = 5f;
                headerTable1.AddCell(docNoCell);

                document.Add(headerTable1);
                document.Add(new Paragraph("\n"));

                Paragraph mainTitle = new Paragraph();
                mainTitle.Alignment = Element.ALIGN_CENTER;
                Chunk noteChunk = new Chunk("NOTE", headerFont);
                noteChunk.SetUnderline(0.5f, -1.5f);
                mainTitle.Add(noteChunk);
                mainTitle.SpacingAfter = 2f;
                document.Add(mainTitle);

                Paragraph description = new Paragraph("SUB : " + ESCOM + " Power Purchase Bills for Payment.", normalFont);
                description.Alignment = Element.ALIGN_CENTER;
                document.Add(description);

                Paragraph description2 = new Paragraph("Following are the Power Purchase bills for the month of " + DateTime.Now.ToString("MMM-y") + " for Payment.", normalFont);
                description2.Alignment = Element.ALIGN_CENTER;
                description2.SpacingAfter = 15f;
                document.Add(description2);

                PdfPTable billTable = new PdfPTable(6);
                float[] columnWidths = new float[] { 5f, 25f, 20f, 15f, 20f, 20f };
                billTable.SetWidths(columnWidths);
                billTable.WidthPercentage = 90;
                billTable.HorizontalAlignment = Element.ALIGN_CENTER;
                billTable.SpacingBefore = 0f;
                billTable.SpacingAfter = 0f;

                string[] headers = { "SL No", "Company Name", "B.R.No/Date", "Net Energy", "Amount", "Due Date" };
                foreach (string headerText in headers)
                {
                    PdfPCell headerCell = new PdfPCell(new Phrase(new Chunk(headerText, new Font(Font.FontFamily.UNDEFINED, 10f, Font.BOLD))));
                    headerCell.HorizontalAlignment = PdfPCell.ALIGN_CENTER;
                    headerCell.VerticalAlignment = PdfPCell.ALIGN_MIDDLE;
                    headerCell.FixedHeight = 20f;
                    billTable.AddCell(headerCell);
                }

                string[] Param = new string[2];
                string[] PName = new string[2];

                Param[0] = receiptNo;
                PName[0] = "@RECEIPT_NO";
                Param[1] = ESCOM;
                PName[1] = "@ESCOM";

                int slNoCounter = 1;
                decimal totalAmount = 0;

                DataTable dtt1 = new DataTable();
                dtt1 = SqlCmd.SelectData("SP_LETTER_DETAILS_Q2", Param, PName, 2);

                if (dtt1 == null || dtt1.Rows.Count == 0)
                {
                    return new { success = false, message = "No data found for Receipt No: " + receiptNo };
                }

                foreach (DataRow row in dtt1.Rows)
                {
                    billTable.AddCell(new PdfPCell(new Phrase(slNoCounter.ToString(), normalFont))
                    {
                        HorizontalAlignment = PdfPCell.ALIGN_CENTER,
                        VerticalAlignment = PdfPCell.ALIGN_MIDDLE,
                        FixedHeight = 40f
                    });

                    billTable.AddCell(new PdfPCell(new Phrase(row["PL_FIRMNAME"].ToString(), normalFont))
                    {
                        HorizontalAlignment = PdfPCell.ALIGN_LEFT,
                        VerticalAlignment = PdfPCell.ALIGN_MIDDLE,
                        FixedHeight = 40f
                    });

                    billTable.AddCell(new PdfPCell(new Phrase(row["BR_NO"].ToString() + "/" + row["BR_DATE"].ToString(), normalFont))
                    {
                        HorizontalAlignment = PdfPCell.ALIGN_CENTER,
                        VerticalAlignment = PdfPCell.ALIGN_MIDDLE,
                        FixedHeight = 40f
                    });

                    billTable.AddCell(new PdfPCell(new Phrase(row["NET_ENERGY"].ToString(), normalFont))
                    {
                        HorizontalAlignment = PdfPCell.ALIGN_RIGHT,
                        VerticalAlignment = PdfPCell.ALIGN_MIDDLE,
                        FixedHeight = 40f
                    });

                    decimal amount = Convert.ToDecimal(row["NET_PAYABLE"]);
                    totalAmount += amount;
                    billTable.AddCell(new PdfPCell(new Phrase(amount.ToString("N2"), normalFont))
                    {
                        HorizontalAlignment = PdfPCell.ALIGN_RIGHT,
                        VerticalAlignment = PdfPCell.ALIGN_MIDDLE,
                        FixedHeight = 40f
                    });

                    billTable.AddCell(new PdfPCell(new Phrase(Convert.ToDateTime(row["BR_DATE"]).ToString("dd-MMM-yy"), normalFont))
                    {
                        HorizontalAlignment = PdfPCell.ALIGN_CENTER,
                        VerticalAlignment = PdfPCell.ALIGN_MIDDLE,
                        FixedHeight = 40f
                    });

                    slNoCounter++;
                }

                PdfPCell totalLabelCell = new PdfPCell(new Phrase("Total Amount", new Font(Font.FontFamily.UNDEFINED, 10f, Font.BOLD)))
                {
                    Colspan = 5,
                    HorizontalAlignment = PdfPCell.ALIGN_RIGHT,
                    VerticalAlignment = PdfPCell.ALIGN_MIDDLE,
                    FixedHeight = 20f
                };
                billTable.AddCell(totalLabelCell);

                PdfPCell totalAmountCell = new PdfPCell(new Phrase(totalAmount.ToString("N2"), new Font(Font.FontFamily.UNDEFINED, 10f, Font.BOLD)))
                {
                    HorizontalAlignment = PdfPCell.ALIGN_RIGHT,
                    VerticalAlignment = PdfPCell.ALIGN_MIDDLE,
                    FixedHeight = 20f
                };
                billTable.AddCell(totalAmountCell);

                document.Add(billTable);
                document.Add(new Paragraph("\n"));

                AddSignatureSection(document, ESCOM, normalFont, headerFont, smallFont);

                Paragraph sys = new Paragraph("This is System Generated Signature is not Required                            Generated On  " + DateTime.Now, normalFont);
                sys.Alignment = Element.ALIGN_CENTER;
                document.Add(sys);

                document.Close();

                byte[] bytes = memoryStream.ToArray();

                string fname = ESCOM + "_PowerPurchase_Bills_" + DateTime.Now.ToString("yyyy-MM-dd-HH-mm-ss") + ".pdf";

                string mainDirectory = @"D:\GTD_Documents\PPA\CoveringDetails";
                Directory.CreateDirectory(mainDirectory);
                string mainFilePath = Path.Combine(mainDirectory, fname);
                File.WriteAllBytes(mainFilePath, bytes);

                /*  string webDirectory = HttpContext.Current.Server.MapPath("~/Files/REGULAR");
                  Directory.CreateDirectory(webDirectory);
                  string webFilePath = Path.Combine(webDirectory, fname);
                  File.WriteAllBytes(webFilePath, bytes);*/

                string base64String = Convert.ToBase64String(bytes);
                return new
                {
                    success = true,
                    pdfData = base64String,
                    fileName = fname,
                    savedPath = mainFilePath,
                };
            }
        }
        catch (Exception ex)
        {
            return new
            {
                success = false,
                fileName = "",
                message = ex.Message
            };
        }
    }

    private static void AddSignatureSection(Document document, string ESCOM, Font normalFont, Font headerFont, Font smallFont)
    {
        if (ESCOM == "BESCOM")
        {
            PdfPTable signatureTable = new PdfPTable(1);
            signatureTable.WidthPercentage = 30;
            signatureTable.HorizontalAlignment = Element.ALIGN_RIGHT;

            PdfPCell signatureSpaceCell = new PdfPCell(new Phrase(" "));
            signatureSpaceCell.FixedHeight = 10f;
            signatureSpaceCell.Border = PdfPCell.NO_BORDER;
            signatureTable.AddCell(signatureSpaceCell);

            PdfPCell nameCell = new PdfPCell(new Phrase("General Manager (Else)", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 10f, Font.BOLD)));
            nameCell.Border = PdfPCell.NO_BORDER;
            nameCell.HorizontalAlignment = Element.ALIGN_CENTER;
            signatureTable.AddCell(nameCell);

            PdfPCell designationCell = new PdfPCell(new Phrase("Power Purchase, " + ESCOM, FontFactory.GetFont(FontFactory.TIMES_ROMAN, 9f)));
            designationCell.Border = PdfPCell.NO_BORDER;
            designationCell.HorizontalAlignment = Element.ALIGN_CENTER;
            signatureTable.AddCell(designationCell);

            document.Add(signatureTable);
            document.Add(new Paragraph("\n"));
        }
        else if (ESCOM == "CESC")
        {
            document.Add(new Paragraph("\n\n\n"));
            PdfPTable signatureTable = new PdfPTable(2);
            signatureTable.WidthPercentage = 80;
            signatureTable.SetWidths(new float[] { 50f, 50f });

            Paragraph leftPara = new Paragraph("Manager-3 (EBC-A)", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 10f, Font.BOLD));
            leftPara.Alignment = Element.ALIGN_LEFT;

            PdfPCell leftCell12 = new PdfPCell();
            leftCell12.Border = PdfPCell.NO_BORDER;
            leftCell12.AddElement(leftPara);

            Paragraph rightPara12 = new Paragraph("AGM(EBC-A)", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 10f, Font.BOLD));
            rightPara12.Alignment = Element.ALIGN_RIGHT;

            PdfPCell rightCell12 = new PdfPCell();
            rightCell12.Border = PdfPCell.NO_BORDER;
            rightCell12.AddElement(rightPara12);

            signatureTable.AddCell(leftCell12);
            signatureTable.AddCell(rightCell12);

            document.Add(signatureTable);
            document.Add(new Paragraph("\n"));
        }
        else if (ESCOM == "HESCOM")
        {
            document.Add(new Paragraph("\n\n"));

            PdfPTable signatureTable = new PdfPTable(3);
            signatureTable.WidthPercentage = 100;

            PdfPCell nameCell = new PdfPCell(new Phrase("Sr.Assistant", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 10f, Font.BOLD)));
            nameCell.Border = PdfPCell.NO_BORDER;
            nameCell.HorizontalAlignment = Element.ALIGN_CENTER;
            signatureTable.AddCell(nameCell);

            PdfPCell nameCell1 = new PdfPCell(new Phrase("Asst.Account Officer", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 10f, Font.BOLD)));
            nameCell1.Border = PdfPCell.NO_BORDER;
            nameCell1.HorizontalAlignment = Element.ALIGN_CENTER;
            signatureTable.AddCell(nameCell1);

            PdfPCell nameCell2 = new PdfPCell(new Phrase("Account Officer", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 10f, Font.BOLD)));
            nameCell2.Border = PdfPCell.NO_BORDER;
            nameCell2.HorizontalAlignment = Element.ALIGN_CENTER;
            signatureTable.AddCell(nameCell2);

            PdfPCell designationCell = new PdfPCell(new Phrase("PTC Section Hubballi", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 9f, Font.ITALIC)));
            designationCell.Border = PdfPCell.NO_BORDER;
            designationCell.HorizontalAlignment = Element.ALIGN_CENTER;
            signatureTable.AddCell(designationCell);

            PdfPCell designationCell1 = new PdfPCell(new Phrase("PTC Section Hubballi", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 9f, Font.ITALIC)));
            designationCell1.Border = PdfPCell.NO_BORDER;
            designationCell1.HorizontalAlignment = Element.ALIGN_CENTER;
            signatureTable.AddCell(designationCell1);

            PdfPCell designationCel2 = new PdfPCell(new Phrase("PTC Section Hubballi", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 9f, Font.ITALIC)));
            designationCel2.Border = PdfPCell.NO_BORDER;
            designationCel2.HorizontalAlignment = Element.ALIGN_CENTER;
            signatureTable.AddCell(designationCel2);

            document.Add(signatureTable);
            document.Add(new Paragraph("\n"));
        }
        else if (ESCOM == "GESCOM")
        {
            document.Add(new Paragraph("\n\n\n"));
            PdfPTable signatureTable = new PdfPTable(1);
            signatureTable.WidthPercentage = 30;
            signatureTable.HorizontalAlignment = Element.ALIGN_RIGHT;

            PdfPCell nameCell = new PdfPCell(new Phrase("Executive Engineer(Ele.)", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 10f, Font.BOLD)));
            nameCell.Border = PdfPCell.NO_BORDER;
            nameCell.HorizontalAlignment = Element.ALIGN_CENTER;
            signatureTable.AddCell(nameCell);

            PdfPCell designationCell = new PdfPCell(new Phrase("PTC," + ESCOM + ", Kalaburagi.", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 9f, Font.BOLD)));
            designationCell.Border = PdfPCell.NO_BORDER;
            designationCell.HorizontalAlignment = Element.ALIGN_CENTER;
            signatureTable.AddCell(designationCell);

            document.Add(signatureTable);
            document.Add(new Paragraph("\n"));
        }
        else if (ESCOM == "MESCOM")
        {
            document.Add(new Paragraph("\n\n\n"));
            PdfPTable signatureTable = new PdfPTable(2);
            signatureTable.WidthPercentage = 100;
            signatureTable.SetWidths(new float[] { 50f, 50f });

            Paragraph leftPara = new Paragraph("AAO-EBC", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 10f, Font.BOLD));
            leftPara.Alignment = Element.ALIGN_LEFT;

            PdfPCell leftCell12 = new PdfPCell();
            leftCell12.Border = PdfPCell.NO_BORDER;
            leftCell12.AddElement(leftPara);

            Paragraph rightPara12 = new Paragraph("AO-EBC", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 10f, Font.BOLD));
            rightPara12.Alignment = Element.ALIGN_RIGHT;

            PdfPCell rightCell12 = new PdfPCell();
            rightCell12.Border = PdfPCell.NO_BORDER;
            rightCell12.AddElement(rightPara12);

            signatureTable.AddCell(leftCell12);
            signatureTable.AddCell(rightCell12);

            document.Add(signatureTable);
            document.Add(new Paragraph("\n"));
        }
    }

    [WebMethod]
    public static object SendToPayment(List<ChequeDto> cheques)
    {
        try
        {
            if (cheques == null || cheques.Count == 0)
            {
                return new { success = false, message = "No records selected." };
            }

            string ESCOM = HttpContext.Current.Session["ESCOM_NAME"].ToString() ?? "";
            int successCount = 0;

            foreach (var item in cheques)
            {
                string[] Param = new string[6];
                string[] PName = new string[6];

                string letterNo = item.RECEIPT_NO;

            
                Param[0] = letterNo;
                PName[0] = "@RECEIPT_NO";

                Param[1] = ESCOM;
                PName[1] = "@ESCOMS";

                DataTable dtGetId = SqlCmd.SelectData("SP_LETTER_DETAILS_Q5", Param, PName, 2);

                if (dtGetId.Rows.Count == 0)
                    continue;

                foreach (DataRow row in dtGetId.Rows)
                {
                    string ppaId = row["BT_PPA_ID"].ToString();
                    string ppaPLId = row["BT_PL_ID"].ToString();
                    string unId = row["BT_SLNO"].ToString();

                
                    Param[0] = ppaId;
                    PName[0] = "@PPA_ID";

                    Param[1] = ppaPLId;
                    PName[1] = "@PL_ID";

                    DataTable dtGetId2 = SqlCmd.SelectData("SP_LETTER_DETAILS_Q6", Param, PName, 2);

                    if (dtGetId2.Rows.Count == 0)
                    {
                        return new { success = false, message = "Please add bank details for some beneficiaries." };
                    }

                    string ac_Num = dtGetId2.Rows[0]["Account_No"].ToString();
                    string branch = dtGetId2.Rows[0]["Banks_Address"].ToString();
                    string address = dtGetId2.Rows[0]["Banks_Address"].ToString();
                    string acHolderName = dtGetId2.Rows[0]["PPA_UNAME"].ToString();
                    string ifsCode = dtGetId2.Rows[0]["IFSC"].ToString();
                    string nameOfTheBank = dtGetId2.Rows[0]["Name_of_Banks"].ToString();

                  
                    Param = new string[6];
                    PName = new string[6];

                    Param[0] = unId;
                    PName[0] = "@BT_SLNO_ID";

                    Param[1] = acHolderName;
                    PName[1] = "@CREDIT_ACC_HOLDER_NAME";

                    Param[2] = ac_Num;
                    PName[2] = "@CREDIT_ACCOUNTNO";

                    Param[3] = nameOfTheBank;
                    PName[3] = "@CREDIT_BANKNAME";

                    Param[4] = branch;
                    PName[4] = "@CREDIT_BRANCH_NAME";

                    Param[5] = ifsCode;
                    PName[5] = "@CREDIT_IFSCCODE";

                    SqlCmd.ExecNonQuery("SP_LETTER_DETAILS_Q7", Param, PName, 6);
                }

             
                string appIn = "", appIn2 = "";

                switch (ESCOM)
                {
                    case "BESCOM": appIn = "59"; appIn2 = "5"; break;
                    case "HESCOM": appIn = "93"; appIn2 = "110"; break;
                    case "MESCOM": appIn = "69"; appIn2 = "64"; break;
                    case "CESC": appIn = "75"; appIn2 = "70"; break;
                    case "GESCOM": appIn = "108"; appIn2 = "131"; break;
                }

                Param = new string[4];
                PName = new string[4];

                Param[0] = letterNo;
                PName[0] = "@RECEIPT_NO";

                Param[1] = ESCOM;
                PName[1] = "@ESCOMS";

                Param[2] = appIn;
                PName[2] = "@App_In";

                Param[3] = appIn2;
                PName[3] = "@App_In2";

                int result = SqlCmd.ExecNonQuery("SP_LETTER_DETAILS_Q3", Param, PName, 4);

                if (result > 0)
                    successCount++;
            }

            return new
            {
                success = true,
                message = successCount + " letter(s) sent to payment successfully."
            };
        }
        catch (Exception ex)
        {
            return new { success = false, message = ex.Message };
        }
    }

   
    /* protected void txtMonth_TextChanged(object sender, EventArgs e)
     {


         try
         {
             FetchDataForGenerateAt();
         }
         catch (Exception Ex)
         {

         }
     }*/

    /*[WebMethod]
    public static string FetchDataForGenerateAt(string month)
    {
        try
        {
            DateTime monthYear = DateTime.ParseExact(month, "MMM-yyyy", System.Globalization.CultureInfo.InvariantCulture);

            string[] param = new string[2];
            string[] pName = new string[2];

            param[0] = monthYear.ToString("MMyyyy");
            pName[0] = "@FB_MONTH";

            string escomValue = HttpContext.Current.Session["ESCOM_NAME"] != null
                ? HttpContext.Current.Session["ESCOM_NAME"].ToString()
                : "";

            param[1] = escomValue;
            pName[1] = "@ESCOMS";

            DataTable dt = SqlCmd.SelectData("SP_GET_BENIFICIARYDEATAILS", param, pName, 2);
            DataTable dtCheq = SqlCmd.SelectData("SP_LETTER_DETAILS_Q1", param, pName, 2);

            var result = new
            {
                success = true,
                beneficiaryData = dt.Rows.Count > 0 ? ConvertDataTableToList(dt) : new List<Dictionary<string, object>>(),
                chequeData = dtCheq.Rows.Count > 0 ? ConvertDataTableToList(dtCheq) : new List<Dictionary<string, object>>(),
                beneficiaryCount = dt.Rows.Count,
                chequeCount = dtCheq.Rows.Count
            };

            return new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(result);
        }
        catch (Exception ex)
        {
            var errorResult = new
            {
                success = false,
                message = ex.Message
            };
            return new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(errorResult);
        }
    }*/


    [WebMethod(EnableSession = true)]
    public static object FetchDataForGenerateAt(string month)
    {
        try
        {
            if (string.IsNullOrEmpty(month))
            {
                return new { success = false, message = "Month is required" };
            }

            DateTime parsedDate;
            string monthValue = "";

            if (!DateTime.TryParseExact(month, "MMM-yyyy",
                System.Globalization.CultureInfo.InvariantCulture,
                System.Globalization.DateTimeStyles.None,
                out parsedDate))
            {
                return new { success = false, message = "Invalid Month Format" };
            }

            monthValue = parsedDate.ToString("MM") + parsedDate.ToString("yyyy");

            string[] param = new string[2];
            string[] pName = new string[2];

            param[0] = monthValue;
            pName[0] = "@FB_MONTH";

            string escomValue = HttpContext.Current.Session["ESCOM_NAME"] != null
                ? HttpContext.Current.Session["ESCOM_NAME"].ToString()
                : "";

            param[1] = escomValue;
            pName[1] = "@ESCOMS";

            DataTable dt = SqlCmd.SelectData("SP_GET_BENIFICIARYDEATAILS", param, pName, 2);
            DataTable dtCheq = SqlCmd.SelectData("SP_LETTER_DETAILS_Q1", param, pName, 2);

            return new
            {
                success = true,
                beneficiaryData = ConvertDataTableToList(dt),
                chequeData = ConvertDataTableToList(dtCheq),
                beneficiaryCount = dt.Rows.Count,
                chequeCount = dtCheq.Rows.Count
            };
        }
        catch (Exception ex)
        {
            return new { success = false, message = ex.Message };
        }
    }

    private static List<Dictionary<string, object>> ConvertDataTableToList(DataTable dt)
    {
        var list = new List<Dictionary<string, object>>();
        foreach (DataRow row in dt.Rows)
        {
            var dict = new Dictionary<string, object>();
            foreach (DataColumn col in dt.Columns)
            {
                dict[col.ColumnName] = row[col] == DBNull.Value ? null : row[col];
            }
            list.Add(dict);
        }
        return list;
    }

    [WebMethod]
    public static object DownloadJV(string partAgencyId, string beneficaryName, string month)
    {

        try
        {
            if (string.IsNullOrWhiteSpace(partAgencyId))
                return new { success = false, message = "Part Agency ID is required." };

            if (string.IsNullOrWhiteSpace(beneficaryName))
                return new { success = false, message = "Beneficiary Name is required." };

            if (string.IsNullOrWhiteSpace(month))
                return new { success = false, message = "Month is required." };

            decimal totalAmount = 0, total3 = 0, total5 = 0, totalAmount1 = 0;
            string partAgencyIdValue = partAgencyId;
            string beneficaryNameValue = beneficaryName;

            string ESCOM = HttpContext.Current.Session["ESCOM_NAME"].ToString() ?? "";

            string comName = "", billDate = "";
            string logoPath = "";

            switch (ESCOM)
            {
                case "BESCOM":
                    comName = "BANGALORE ELECTRICITY SUPPLY COMPANY LIMITED";
                    logoPath = "https://kptclgtd.com/assets/images/BESCOMLOGO.png";
                    break;
                case "CESC":
                    comName = "CHAMUNDESHWARI ELECTRICITY SUPPLY CORPORATION LIMITED";
                    logoPath = "https://kptclgtd.com/assets/images/cesc1.png";
                    break;
                case "MESCOM":
                    comName = "MANGALORE ELECTRICITY SUPPLY COMPANY LIMITED";
                    logoPath = "https://kptclgtd.com/assets/images/MESCOMLOGO.png";
                    break;
                case "HESCOM":
                    comName = "HUBLI ELECTRICITY SUPPLY COMPANY LIMITED";
                    logoPath = "https://kptclgtd.com/assets/images/HESCOMLOGO.JPg";
                    break;
                case "GESCOM":
                    comName = "GULBARGA ELECTRICITY SUPPLY COMPANY LIMITED";
                    logoPath = "https://kptclgtd.com/assets/images/GESCOMLOGO.png";
                    break;
            }

            /*            DateTime billdt = DateTime.ParseExact(month, "MMM-yyyy", System.Globalization.CultureInfo.InvariantCulture);
            */
            DateTime billdt;
            if (!DateTime.TryParseExact(month, "MMM-yyyy", CultureInfo.InvariantCulture,
                DateTimeStyles.None, out billdt))
            {
                return new { success = false, message = "Invalid month format. Expected MMM-yyyy" };
            }
            billDate = billdt.ToString("MMyyyy");

            string[] Param = new string[2];
            string[] PName = new string[2];

            Param[0] = partAgencyIdValue; PName[0] = "@FB_COMPID";
            Param[1] = billDate; PName[1] = "@FB_MONTH";
            DataTable dtCal = SqlCmd.SelectData("SP_GET_ENERGY_Q1", Param, PName, 2);
            total3 = dtCal != null && dtCal.Rows.Count > 0 ? Convert.ToDecimal(dtCal.Rows[0]["VALUE"]) : 0;

            Param[0] = partAgencyIdValue; PName[0] = "@BT_PPA_ID";
            Param[1] = billDate; PName[1] = "@FB_MONTH";
            DataTable dtDet = SqlCmd.SelectData("SP_GET_PAYMENT_DETAILS_Q1", Param, PName, 2);

            if (dtDet == null || dtDet.Rows.Count == 0)
            {
                var errorResult = new Dictionary<string, object>
            {
                { "success", false },
                { "message", "No data found" }
            };
                /*                return new JavaScriptSerializer().Serialize(errorResult);*/
                return new
                {
                    success = false,
                    message = "No data found"
                };
            }

            DataRow row = dtDet.Rows[0];
            string billmonth = row["FB_MONTH"] != DBNull.Value ? row["FB_MONTH"].ToString() : "000000";

            decimal meterReading = GetDecimal(row["METER_R_CHAR"]);
            decimal Neternergy = GetDecimal(row["NET_ENERGY"]);
            decimal rebate = GetDecimal(row["REBATE"]);
            decimal cgst = GetDecimal(row["CGST"]);
            decimal sgst = GetDecimal(row["SGST"]);
            decimal tds = GetDecimal(row["TDS"]);
            decimal kvarh = GetDecimal(row["KVARH_CHARGES"]);
            decimal netPayable = GetDecimal(row["NET_PAYABLE"]);
            decimal rate = GetDecimal(row["PPA_RATE"]);

            string jvNo = row["JV_no"] != DBNull.Value ? row["JV_no"].ToString() : "";
            string jvDate = row["JV_DATE"] != DBNull.Value ? Convert.ToDateTime(row["JV_DATE"]).ToString("dd-MM-yyyy") : "";
            string brNo = row["BR_NO"] != DBNull.Value ? row["BR_NO"].ToString() : "";
            string brDate = row["BR_DATE"] != DBNull.Value ? Convert.ToDateTime(row["BR_DATE"]).ToString("dd/MM/yyyy") : "";

            decimal sgst1 = sgst / 2;
            decimal totalAmounts345 = netPayable + rebate + meterReading + kvarh + tds + sgst;

            Document document = new Document(PageSize.A4, 30f, 30f, 30f, 30f);
            using (var memoryStream = new System.IO.MemoryStream())
            {
                PdfWriter writer = PdfWriter.GetInstance(document, memoryStream);
                document.Open();

                Font headerFont = FontFactory.GetFont(FontFactory.TIMES_ROMAN, 12f, Font.BOLD);
                Font normalFont = FontFactory.GetFont(FontFactory.TIMES_ROMAN, 10f);

                iTextSharp.text.Image logo = iTextSharp.text.Image.GetInstance(logoPath);
                logo.ScaleAbsolute(50f, 50f);
                logo.Alignment = Element.ALIGN_LEFT;

                // Header Table
                PdfPTable headerTable = new PdfPTable(2);
                headerTable.WidthPercentage = 100;
                headerTable.SetWidths(new float[] { 15f, 85f });
                headerTable.SpacingAfter = 10f;

                PdfPCell logoCell = new PdfPCell(logo);
                logoCell.Border = PdfPCell.NO_BORDER;
                logoCell.HorizontalAlignment = Element.ALIGN_LEFT;
                logoCell.VerticalAlignment = Element.ALIGN_MIDDLE;

                Paragraph heading1 = new Paragraph();
                heading1.Alignment = Element.ALIGN_CENTER;
                Chunk line1 = new Chunk(comName, headerFont);
                line1.SetUnderline(0.5f, -1.5f);
                heading1.Add(line1);

                PdfPCell headingCell = new PdfPCell(heading1);
                headingCell.Border = PdfPCell.NO_BORDER;
                headingCell.HorizontalAlignment = Element.ALIGN_CENTER;
                headingCell.VerticalAlignment = Element.ALIGN_MIDDLE;

                headerTable.AddCell(logoCell);
                headerTable.AddCell(headingCell);
                document.Add(headerTable);

                Paragraph heading2 = new Paragraph("Journal Voucher", headerFont);
                heading2.Alignment = Element.ALIGN_CENTER;
                heading2.SpacingAfter = 15f;
                document.Add(heading2);

                if (ESCOM == "BESCOM")
                {
                    PdfPTable container = new PdfPTable(2);
                    container.WidthPercentage = 100;
                    container.SetWidths(new float[] { 40f, 60f });

                    PdfPTable leftInnerTable = new PdfPTable(2);
                    leftInnerTable.WidthPercentage = 100;
                    leftInnerTable.SetWidths(new float[] { 40f, 60f });

                    leftInnerTable.AddCell(CreateBorderedCell("JV NO", normalFont));
                    leftInnerTable.AddCell(CreateBorderedCell(jvNo, normalFont));
                    leftInnerTable.AddCell(CreateBorderedCell("JV Date", normalFont));
                    leftInnerTable.AddCell(CreateBorderedCell(jvDate, normalFont));

                    PdfPCell leftCell = new PdfPCell(leftInnerTable);
                    leftCell.Border = PdfPCell.NO_BORDER;
                    leftCell.Padding = 5f;
                    leftCell.VerticalAlignment = Element.ALIGN_TOP;

                    Paragraph rightPara = new Paragraph();
                    rightPara.Alignment = Element.ALIGN_RIGHT;
                    rightPara.Add(new Phrase("Accounting Unit: PP\n", normalFont));
                    rightPara.Add(new Phrase("Location Code:", normalFont));

                    PdfPCell rightCell = new PdfPCell(rightPara);
                    rightCell.Border = PdfPCell.NO_BORDER;
                    rightCell.PaddingLeft = 190f;
                    rightCell.PaddingTop = 5f;
                    rightCell.VerticalAlignment = Element.ALIGN_TOP;

                    container.AddCell(leftCell);
                    container.AddCell(rightCell);
                    document.Add(container);
                }
                else
                {
                    PdfPTable container = new PdfPTable(1);
                    container.WidthPercentage = 40;
                    container.HorizontalAlignment = Element.ALIGN_LEFT;

                    PdfPTable leftInnerTable = new PdfPTable(2);
                    leftInnerTable.WidthPercentage = 100;
                    leftInnerTable.SetWidths(new float[] { 40f, 60f });

                    leftInnerTable.AddCell(CreateBorderedCell("JV NO", normalFont));
                    leftInnerTable.AddCell(CreateBorderedCell(jvNo, normalFont));
                    leftInnerTable.AddCell(CreateBorderedCell("JV Date", normalFont));
                    leftInnerTable.AddCell(CreateBorderedCell(jvDate, normalFont));

                    PdfPCell leftCell = new PdfPCell(leftInnerTable);
                    leftCell.Border = PdfPCell.NO_BORDER;
                    leftCell.Padding = 5f;
                    leftCell.HorizontalAlignment = Element.ALIGN_LEFT;
                    leftCell.VerticalAlignment = Element.ALIGN_TOP;

                    container.AddCell(leftCell);
                    document.Add(container);
                }

                DateTime dtJv = DateTime.ParseExact(billmonth, "MMyyyy", System.Globalization.CultureInfo.InvariantCulture);
                Paragraph centeredText = new Paragraph("J.V. For The Month of " + dtJv.ToString("MMM-yyyy"), normalFont);
                centeredText.Alignment = Element.ALIGN_CENTER;
                centeredText.SpacingBefore = 5f;
                document.Add(centeredText);
                document.Add(new Paragraph("\n"));

                // Details Table
                PdfPTable detailsTable = new PdfPTable(3);
                detailsTable.WidthPercentage = 100;
                detailsTable.SetWidths(new float[] { 60f, 20f, 20f });

                detailsTable.AddCell(new PdfPCell(new Phrase("PARTICULARS", headerFont)) { HorizontalAlignment = Element.ALIGN_CENTER });
                detailsTable.AddCell(new PdfPCell(new Phrase("DEBIT IN Rs", headerFont)) { HorizontalAlignment = Element.ALIGN_CENTER });
                detailsTable.AddCell(new PdfPCell(new Phrase("CREDIT IN Rs", headerFont)) { HorizontalAlignment = Element.ALIGN_CENTER });

                detailsTable.AddCell(new Phrase("To 70.3027 Power Purchase From " + beneficaryNameValue, normalFont));
                detailsTable.AddCell(new Phrase(Math.Round(totalAmounts345).ToString("N0"), normalFont));
                detailsTable.AddCell(new Phrase("", normalFont));

                detailsTable.AddCell(new Phrase("To 41.3027 Sy. Crs. for Purchase of Power from " + beneficaryNameValue, normalFont));
                detailsTable.AddCell(new Phrase("", normalFont));
                detailsTable.AddCell(new Phrase(netPayable.ToString("N2"), normalFont));

                detailsTable.AddCell(new Phrase("To 62.9187 Rebate", normalFont));
                detailsTable.AddCell(new Phrase("", normalFont));
                detailsTable.AddCell(new Phrase(rebate.ToString("N2"), normalFont));

                detailsTable.AddCell(new Phrase("To 62.937 Miscellaneous Recoveries", normalFont));
                detailsTable.AddCell(new Phrase("", normalFont));
                detailsTable.AddCell(new Phrase(meterReading.ToString("N2"), normalFont));

                detailsTable.AddCell(new Phrase("To 46.491 CGST", normalFont));
                detailsTable.AddCell(new Phrase("", normalFont));
                detailsTable.AddCell(new Phrase(sgst1.ToString("N2"), normalFont));

                detailsTable.AddCell(new Phrase("To 46.492 SGST", normalFont));
                detailsTable.AddCell(new Phrase("", normalFont));
                detailsTable.AddCell(new Phrase(sgst1.ToString("N2"), normalFont));

                detailsTable.AddCell(new Phrase("To 62.912 KVARH", normalFont));
                detailsTable.AddCell(new Phrase("", normalFont));
                detailsTable.AddCell(new Phrase(kvarh.ToString("N2"), normalFont));

                detailsTable.AddCell(new Phrase("To 46.924 TDS", normalFont));
                detailsTable.AddCell(new Phrase("", normalFont));
                detailsTable.AddCell(new Phrase(tds.ToString("N2"), normalFont));

                PdfPCell narrationCell = new PdfPCell(new Phrase(
                    "Being the entry passed to bring in to account the Power Purchase from " + beneficaryNameValue +
                    ". vide BR No. " + brNo + "/" + brDate, normalFont));
                narrationCell.Colspan = 2;
                detailsTable.AddCell(narrationCell);
                detailsTable.AddCell(new Phrase("", normalFont));

                PdfPCell totalCell = new PdfPCell(new Phrase("Grand Total", headerFont));
                totalCell.HorizontalAlignment = Element.ALIGN_CENTER;
                totalCell.Colspan = 1;
                detailsTable.AddCell(totalCell);
                detailsTable.AddCell(new Phrase(Math.Round(totalAmounts345).ToString("N0"), headerFont));
                detailsTable.AddCell(new Phrase(Math.Round(totalAmounts345).ToString("N0"), headerFont));

                document.Add(detailsTable);

                if (ESCOM == "BESCOM")
                {
                    document.Add(new Paragraph("\n\n\n\n"));
                    PdfPTable signatureTable = new PdfPTable(1);
                    signatureTable.WidthPercentage = 30;
                    signatureTable.HorizontalAlignment = Element.ALIGN_RIGHT;

                    PdfPCell approvedCell = new PdfPCell(new Phrase("Approved", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 10f)));
                    approvedCell.Border = PdfPCell.NO_BORDER;
                    approvedCell.HorizontalAlignment = Element.ALIGN_CENTER;
                    signatureTable.AddCell(approvedCell);

                    PdfPCell signatureImageCell = new PdfPCell(new Phrase(" "));
                    signatureImageCell.FixedHeight = 30f;
                    signatureImageCell.Border = PdfPCell.NO_BORDER;
                    signatureTable.AddCell(signatureImageCell);

                    PdfPCell nameCell = new PdfPCell(new Phrase("Deputy General Manager (F&C)", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 10f, Font.BOLD)));
                    nameCell.Border = PdfPCell.NO_BORDER;
                    nameCell.HorizontalAlignment = Element.ALIGN_CENTER;
                    signatureTable.AddCell(nameCell);

                    PdfPCell designationCell = new PdfPCell(new Phrase("Power Purchase," + ESCOM, FontFactory.GetFont(FontFactory.TIMES_ROMAN, 9f, Font.ITALIC)));
                    designationCell.Border = PdfPCell.NO_BORDER;
                    designationCell.HorizontalAlignment = Element.ALIGN_CENTER;
                    signatureTable.AddCell(designationCell);

                    document.Add(signatureTable);
                }
                else if (ESCOM == "CESC")
                {
                    document.Add(new Paragraph("\n\n\n"));
                    PdfPTable signatureTable = new PdfPTable(2);
                    signatureTable.WidthPercentage = 100;
                    signatureTable.SetWidths(new float[] { 50f, 50f });

                    Paragraph leftPara = new Paragraph(
                        "Manager-3 (EBC-A)",
                        FontFactory.GetFont(FontFactory.TIMES_ROMAN, 10f, Font.BOLD)
                    );
                    leftPara.Alignment = Element.ALIGN_LEFT;

                    PdfPCell leftCell12 = new PdfPCell();
                    leftCell12.Border = PdfPCell.NO_BORDER;
                    leftCell12.AddElement(leftPara);

                    Paragraph rightPara12 = new Paragraph(
                        "AGM(EBC-A)",
                        FontFactory.GetFont(FontFactory.TIMES_ROMAN, 10f, Font.BOLD)
                    );
                    rightPara12.Alignment = Element.ALIGN_RIGHT;

                    PdfPCell rightCell12 = new PdfPCell();
                    rightCell12.Border = PdfPCell.NO_BORDER;
                    rightCell12.AddElement(rightPara12);

                    // Add cells
                    signatureTable.AddCell(leftCell12);
                    signatureTable.AddCell(rightCell12);

                    document.Add(signatureTable);

                    document.Add(new Paragraph("\n"));

                }
                else if (ESCOM == "MESCOM")
                {

                    document.Add(new Paragraph("\n\n\n"));
                    PdfPTable signatureTable = new PdfPTable(2);
                    signatureTable.WidthPercentage = 100;
                    signatureTable.SetWidths(new float[] { 50f, 50f });

                    Paragraph leftPara = new Paragraph(
                        "AAO-EBC",
                        FontFactory.GetFont(FontFactory.TIMES_ROMAN, 10f, Font.BOLD)
                    );
                    leftPara.Alignment = Element.ALIGN_LEFT;

                    PdfPCell leftCell12 = new PdfPCell();
                    leftCell12.Border = PdfPCell.NO_BORDER;
                    leftCell12.AddElement(leftPara);

                    Paragraph rightPara12 = new Paragraph(
                        "AO-EBC",
                        FontFactory.GetFont(FontFactory.TIMES_ROMAN, 10f, Font.BOLD)
                    );
                    rightPara12.Alignment = Element.ALIGN_RIGHT;

                    PdfPCell rightCell12 = new PdfPCell();
                    rightCell12.Border = PdfPCell.NO_BORDER;
                    rightCell12.AddElement(rightPara12);

                    // Add cells
                    signatureTable.AddCell(leftCell12);
                    signatureTable.AddCell(rightCell12);

                    document.Add(signatureTable);

                    document.Add(new Paragraph("\n"));
                }

                else if (ESCOM == "GESCOM")
                {
                    document.Add(new Paragraph("\n\n\n"));
                    PdfPTable signatureTable = new PdfPTable(1);
                    signatureTable.WidthPercentage = 30;
                    signatureTable.HorizontalAlignment = Element.ALIGN_RIGHT;

                    PdfPCell nameCell = new PdfPCell(new Phrase("Executive Engineer(Ele.)", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 10f, Font.BOLD)));
                    nameCell.Border = PdfPCell.NO_BORDER;
                    nameCell.HorizontalAlignment = Element.ALIGN_CENTER;
                    signatureTable.AddCell(nameCell);

                    PdfPCell designationCell = new PdfPCell(new Phrase("PTC," + ESCOM + ", Kalaburagi.", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 9f, Font.BOLD)));
                    designationCell.Border = PdfPCell.NO_BORDER;
                    designationCell.HorizontalAlignment = Element.ALIGN_CENTER;
                    signatureTable.AddCell(designationCell);

                    document.Add(signatureTable);
                    document.Add(new Paragraph("\n"));
                }
                else if (ESCOM == "HESCOM")
                {
                    document.Add(new Paragraph("\n\n"));
                    PdfPTable signatureTable = new PdfPTable(3);
                    signatureTable.WidthPercentage = 100;

                    PdfPCell nameCell = new PdfPCell(new Phrase("Sr.Assistant", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 10f, Font.BOLD)));
                    nameCell.Border = PdfPCell.NO_BORDER;
                    nameCell.HorizontalAlignment = Element.ALIGN_CENTER;
                    signatureTable.AddCell(nameCell);

                    PdfPCell nameCell1 = new PdfPCell(new Phrase("Asst.Account Officer", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 10f, Font.BOLD)));
                    nameCell1.Border = PdfPCell.NO_BORDER;
                    nameCell1.HorizontalAlignment = Element.ALIGN_CENTER;
                    signatureTable.AddCell(nameCell1);

                    PdfPCell nameCell2 = new PdfPCell(new Phrase("Account Officer", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 10f, Font.BOLD)));
                    nameCell2.Border = PdfPCell.NO_BORDER;
                    nameCell2.HorizontalAlignment = Element.ALIGN_CENTER;
                    signatureTable.AddCell(nameCell2);

                    PdfPCell designationCell = new PdfPCell(new Phrase("PTC Section Hubballi", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 9f, Font.ITALIC)));
                    designationCell.Border = PdfPCell.NO_BORDER;
                    designationCell.HorizontalAlignment = Element.ALIGN_CENTER;
                    signatureTable.AddCell(designationCell);

                    PdfPCell designationCell1 = new PdfPCell(new Phrase("PTC Section Hubballi", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 9f, Font.ITALIC)));
                    designationCell1.Border = PdfPCell.NO_BORDER;
                    designationCell1.HorizontalAlignment = Element.ALIGN_CENTER;
                    signatureTable.AddCell(designationCell1);

                    PdfPCell designationCel2 = new PdfPCell(new Phrase("PTC Section Hubballi", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 9f, Font.ITALIC)));
                    designationCel2.Border = PdfPCell.NO_BORDER;
                    designationCel2.HorizontalAlignment = Element.ALIGN_CENTER;
                    signatureTable.AddCell(designationCel2);

                    document.Add(signatureTable);
                }

                Paragraph sys = new Paragraph("This is System Generated Signature is not Required                            Generated On  " + DateTime.Now, normalFont);
                sys.Alignment = Element.ALIGN_CENTER;
                document.Add(sys);

                document.Close();

                string companyName = beneficaryNameValue.Trim().Replace("/", "_").Replace("\\", "_");
                byte[] bytes = memoryStream.ToArray();

                string fname = companyName + "_" + DateTime.Now.ToString("yyyy-MM-dd-HH-mm-ss") + ".pdf";

                string directoryPath = @"D:\GTD_Documents\PPA\AssignCoveringDetails";
                Directory.CreateDirectory(directoryPath);
                string filePath = Path.Combine(directoryPath, fname);
                File.WriteAllBytes(filePath, bytes);

               /* string webFolder = HttpContext.Current.Server.MapPath("~/Files/REGULAR/");
                Directory.CreateDirectory(webFolder);
                string webFilePath = Path.Combine(webFolder, fname);
                File.Copy(filePath, webFilePath, true);*/

              
                string base64String = Convert.ToBase64String(bytes);

                /*return new JavaScriptSerializer().Serialize(new
                {
                    success = true,
                    pdfData = base64String,
                    fileName = fname,
                    savedPath = filePath,
                   // webPath = "/Files/REGULAR/" + fname
                });*/

                return new
                {
                    success = true,
                    pdfData = base64String,
                    fileName = fname,
                    savedPath = filePath
                };

            }

        }
        catch (Exception ex)
        {
            var errorResult = new Dictionary<string, object>
        {
            { "success", false },
            { "message", ex.Message }
        };
            /*return new JavaScriptSerializer().Serialize(errorResult);*/

            return new
            {
                success = false,
                message = ex.Message
            };

        }
    }

    private static decimal GetDecimal(object value)
    {
        if (value == null || value == DBNull.Value)
            return 0;

        decimal result = 0;
        decimal.TryParse(value.ToString(), out result);
        return result;
    }

    private static PdfPCell CreateBorderedCell(string text, Font font)
    {
        PdfPCell cell = new PdfPCell(new Phrase(text, font));
        cell.Border = PdfPCell.BOX;
        cell.Padding = 5f;
        cell.HorizontalAlignment = Element.ALIGN_LEFT;
        return cell;
    }


    /* protected void btnJV_ClickHescom(string lblId, string lblName)
     {
         try
         {
             // Sample session data
             string ESCOM = HttpContext.Current.Session["KPC_ESCOM"] != null ? HttpContext.Current.Session["KPC_ESCOM"].ToString() : "BESCOM";
             string comName = "", billDate = "";
             string logoPath = "";



             comName = "HUBLI ELECTRICITY SUPPLY COMPANY LIMITED";
             logoPath = Server.MapPath("~/assets/images/HESCOM.jpg");




             decimal totalAmount = 0, total3 = 0, total5 = 0, totalAmount1 = 0;
             //Button btnId = (Button)sender;
             //GridViewRow rowId = (GridViewRow)btnId.NamingContainer;
             //Label lblId = (Label)rowId.FindControl("lblPartAgencyId");
             //Label lblName = (Label)rowId.FindControl("lblBeneficaryName");



             DateTime billdt = DateTime.ParseExact(txtMonth.Text, "MMM-yyyy", System.Globalization.CultureInfo.InvariantCulture);

             string financialYear;
             int year = DateTime.Now.Year; // or your own value
             int month = DateTime.Now.Month;

             if (month >= 4)
             {
                 // Financial year starts in April
                 financialYear = year.ToString() + "-" + ((year + 1) % 100).ToString("00");
             }
             else
             {
                 financialYear = (year - 1).ToString() + "-" + (year % 100).ToString("00");
             }

             billDate = billdt.ToString("MMyyyy");
             string billDate1 = billdt.ToString("MMMM-yyyy");
             Param[0] = lblId; PName[0] = "@FB_COMPID";
             Param[1] = billDate; PName[1] = "@FB_MONTH";

             DataTable dtCal = SqlCmd.SelectData("SP_GET_ENERGY_Q1", Param, PName, Count = 2);
             total3 = Convert.ToDecimal(dtCal.Rows[0]["VALUE"].ToString());




             Param[0] = lblId; PName[0] = "@BT_PPA_ID"; Param[1] = billDate; PName[1] = "@FB_MONTH";
             DataTable dtDet = SqlCmd.SelectData("SP_GET_PAYMENT_DETAILS_Q1", Param, PName, Count = 2);








             decimal meterReading = GetDecimal(dtDet.Rows[0]["METER_R_CHAR"].ToString());
             decimal Neternergy = GetDecimal(dtDet.Rows[0]["NET_ENERGY"].ToString());
             decimal callibration = GetDecimal(dtDet.Rows[0]["CALLIBRATION"].ToString());
             decimal rebate = GetDecimal(dtDet.Rows[0]["REBATE"].ToString());
             decimal cgst = GetDecimal(dtDet.Rows[0]["CGST"].ToString());
             decimal sgst = GetDecimal(dtDet.Rows[0]["SGST"].ToString());
             decimal tds = GetDecimal(dtDet.Rows[0]["TDS"].ToString());
             decimal kvarh = GetDecimal(dtDet.Rows[0]["KVARH_CHARGES"].ToString());
             decimal netPayable = GetDecimal(dtDet.Rows[0]["NET_PAYABLE"].ToString());
             decimal rate = GetDecimal(dtDet.Rows[0]["PPA_RATE"].ToString());
             string jvnumber = dtDet.Rows[0]["JV_NO"].ToString();
             //string javdate = dtDet.Rows[0]["JV_DATE"].ToString();
             decimal sgst1 = sgst / 2;
             // decimal totalAmounts34 = netPayable + rebate + meterReading + kvarh + tds;
             decimal totalAmounts345 = netPayable + rebate + meterReading + kvarh + tds + sgst;

             decimal netenrgyRebat = Neternergy * rate;
             DateTime jvDate;
             string formattedDate = "";
             if (DateTime.TryParse(dtDet.Rows[0]["JV_DATE"].ToString(), out jvDate))
             {
                 formattedDate = jvDate.ToString("dd-MM-yyyy"); // e.g. 05-11-2025
             }
             else
             {
                 formattedDate = ""; // fallback if invalid or null
             }


             // Create the document
             Document document = new Document(PageSize.A4, 30f, 30f, 30f, 30f);
             using (var memoryStream = new System.IO.MemoryStream())
             {
                 PdfWriter writer = PdfWriter.GetInstance(document, memoryStream);
                 document.Open();

                 // Fonts
                 Font headerFont = FontFactory.GetFont(FontFactory.TIMES_ROMAN, 12f, Font.BOLD);
                 Font normalFont = FontFactory.GetFont(FontFactory.TIMES_ROMAN, 10f);


                 iTextSharp.text.Image logo = iTextSharp.text.Image.GetInstance(logoPath);
                 logo.ScaleAbsolute(50f, 50f);
                 logo.Alignment = Element.ALIGN_LEFT;

                 PdfPTable headerTable = new PdfPTable(2);
                 headerTable.WidthPercentage = 100;
                 headerTable.SetWidths(new float[] { 15f, 85f });
                 headerTable.SpacingAfter = 10f;

                 PdfPCell logoCell = new PdfPCell(logo);
                 logoCell.Border = PdfPCell.NO_BORDER;
                 logoCell.HorizontalAlignment = Element.ALIGN_LEFT;
                 logoCell.VerticalAlignment = Element.ALIGN_MIDDLE;

                 Paragraph heading1 = new Paragraph();
                 heading1.Alignment = Element.ALIGN_CENTER;
                 Chunk line1 = new Chunk(comName + ".\n", headerFont);
                 line1.SetUnderline(0.5f, -1.5f);
                 heading1.Add(line1);
                 Chunk line2 = new Chunk("JOURNAL VOUCHER" + ".\n", headerFont);
                 line2.SetUnderline(0.5f, -1.5f);
                 heading1.Add(line2);
                 Chunk line3 = new Chunk("For the month of " + billDate1, headerFont);
                 line3.SetUnderline(0.5f, -1.5f);
                 heading1.Add(line3);

                 PdfPCell headingCell = new PdfPCell(heading1);
                 headingCell.Border = PdfPCell.NO_BORDER;
                 headingCell.HorizontalAlignment = Element.ALIGN_CENTER;
                 headingCell.VerticalAlignment = Element.ALIGN_MIDDLE;

                 headerTable.AddCell(logoCell);
                 headerTable.AddCell(headingCell);

                 document.Add(headerTable);


                 PdfPTable firstdetailsTable = new PdfPTable(4);
                 firstdetailsTable.WidthPercentage = 100;
                 firstdetailsTable.SetWidths(new float[] { 40f, 40f, 60f, 40f });

                 firstdetailsTable.AddCell(new PdfPCell(new Phrase("Financial Year :- ", headerFont))
                 {
                     HorizontalAlignment = Element.ALIGN_LEFT,
                     Border = PdfPCell.NO_BORDER
                 });
                 firstdetailsTable.AddCell(new PdfPCell(new Phrase(financialYear, headerFont))
                 {
                     HorizontalAlignment = Element.ALIGN_LEFT,
                     Border = PdfPCell.NO_BORDER
                 });
                 firstdetailsTable.AddCell(new PdfPCell(new Phrase("", headerFont))
                 {
                     HorizontalAlignment = Element.ALIGN_LEFT,
                     Border = PdfPCell.NO_BORDER
                 });
                 firstdetailsTable.AddCell(new PdfPCell(new Phrase("Corporate Office", headerFont))
                 {
                     HorizontalAlignment = Element.ALIGN_LEFT,
                     Border = PdfPCell.NO_BORDER
                 });

                 firstdetailsTable.AddCell(new PdfPCell(new Phrase("J.V.No:- ", headerFont))
                 {
                     HorizontalAlignment = Element.ALIGN_LEFT,
                     Border = PdfPCell.NO_BORDER
                 });

                 firstdetailsTable.AddCell(new PdfPCell(new Phrase(jvnumber, headerFont))
                 {
                     HorizontalAlignment = Element.ALIGN_LEFT,
                     Border = PdfPCell.NO_BORDER
                 });
                 firstdetailsTable.AddCell(new PdfPCell(new Phrase("", headerFont))
                 {
                     HorizontalAlignment = Element.ALIGN_LEFT,
                     Border = PdfPCell.NO_BORDER
                 });
                 firstdetailsTable.AddCell(new PdfPCell(new Phrase("PTC Section", headerFont))
                 {
                     HorizontalAlignment = Element.ALIGN_LEFT,
                     Border = PdfPCell.NO_BORDER
                 });

                 firstdetailsTable.AddCell(new PdfPCell(new Phrase("Date:-", headerFont))
                 {
                     HorizontalAlignment = Element.ALIGN_LEFT,
                     Border = PdfPCell.NO_BORDER
                 });
                 firstdetailsTable.AddCell(new PdfPCell(new Phrase(formattedDate, headerFont))
                 {
                     HorizontalAlignment = Element.ALIGN_LEFT,
                     Border = PdfPCell.NO_BORDER
                 });
                 firstdetailsTable.AddCell(new PdfPCell(new Phrase("", headerFont))
                 {
                     HorizontalAlignment = Element.ALIGN_LEFT,
                     Border = PdfPCell.NO_BORDER
                 });

                 // "P.H.Road, Navanagar,Hubli"
                 firstdetailsTable.AddCell(new PdfPCell(new Phrase("", headerFont))
                 {
                     HorizontalAlignment = Element.ALIGN_LEFT,
                     Border = PdfPCell.NO_BORDER
                 });

                 firstdetailsTable.AddCell(new PdfPCell(new Phrase("Location Code:- ", headerFont))
                 {
                     HorizontalAlignment = Element.ALIGN_LEFT,
                     Border = PdfPCell.NO_BORDER
                 });
                 firstdetailsTable.AddCell(new PdfPCell(new Phrase("275", headerFont))
                 {
                     HorizontalAlignment = Element.ALIGN_LEFT,
                     Border = PdfPCell.NO_BORDER
                 });
                 firstdetailsTable.AddCell(new PdfPCell(new Phrase("", headerFont))
                 {
                     HorizontalAlignment = Element.ALIGN_LEFT,
                     Border = PdfPCell.NO_BORDER
                 });

                 //"Hubballi"
                 firstdetailsTable.AddCell(new PdfPCell(new Phrase("", headerFont))
                 {
                     HorizontalAlignment = Element.ALIGN_LEFT,
                     Border = PdfPCell.NO_BORDER
                 });

                 document.Add(firstdetailsTable);
                 document.Add(new Paragraph("\n"));

                 PdfPTable detailsTable = new PdfPTable(3);
                 detailsTable.WidthPercentage = 100;
                 detailsTable.SetWidths(new float[] { 60f, 20f, 20f });

                 // === Header Row ===
                 detailsTable.AddCell(new PdfPCell(new Phrase("PARTICULARS", headerFont)) { HorizontalAlignment = Element.ALIGN_CENTER });
                 detailsTable.AddCell(new PdfPCell(new Phrase("DEBIT IN Rs", headerFont)) { HorizontalAlignment = Element.ALIGN_CENTER });
                 detailsTable.AddCell(new PdfPCell(new Phrase("CREDIT IN Rs", headerFont)) { HorizontalAlignment = Element.ALIGN_CENTER });

                 // === Rows from image ===
                 detailsTable.AddCell(new Phrase("To 70.3027 Power Purchase From " + lblName, normalFont));
                 // detailsTable.AddCell(new Phrase(netenrgyRebat.ToString("N2"), normalFont));
                 detailsTable.AddCell(new Phrase(Math.Round(totalAmounts345).ToString("N0"), normalFont));
                 detailsTable.AddCell(new Phrase("", normalFont));

                 detailsTable.AddCell(new Phrase("To 41.3027 Sy. Crs. for Purchase of Power from " + lblName, normalFont));
                 detailsTable.AddCell(new Phrase("", normalFont));
                 detailsTable.AddCell(new Phrase(netPayable.ToString("N2"), normalFont));

                 detailsTable.AddCell(new Phrase("To 62.9187 Rebate", normalFont));
                 detailsTable.AddCell(new Phrase("", normalFont));
                 detailsTable.AddCell(new Phrase(rebate.ToString("N2"), normalFont));

                 detailsTable.AddCell(new Phrase("To 62.937 Miscellaneous Recoveries", normalFont));
                 detailsTable.AddCell(new Phrase("", normalFont));
                 detailsTable.AddCell(new Phrase(meterReading.ToString("N2"), normalFont));

                 detailsTable.AddCell(new Phrase("To 46.491 CGST", normalFont));
                 detailsTable.AddCell(new Phrase("", normalFont));
                 detailsTable.AddCell(new Phrase(sgst1.ToString("N2"), normalFont));

                 detailsTable.AddCell(new Phrase("To 46.492 SGST", normalFont));
                 detailsTable.AddCell(new Phrase("", normalFont));
                 detailsTable.AddCell(new Phrase(sgst1.ToString("N2"), normalFont));

                 detailsTable.AddCell(new Phrase("To 62.912 KVARH", normalFont));
                 detailsTable.AddCell(new Phrase("", normalFont));
                 detailsTable.AddCell(new Phrase(kvarh.ToString("N2"), normalFont));

                 detailsTable.AddCell(new Phrase("To 46.924 TDS", normalFont));
                 detailsTable.AddCell(new Phrase("", normalFont));
                 detailsTable.AddCell(new Phrase(tds.ToString("N2"), normalFont));

                 // === Narration Row ===
                 PdfPCell narrationCell = new PdfPCell(new Phrase("Being the entry passed to bring in to account the\nPower Purchase from " + lblName + " vide BR NO. " + dtDet.Rows[0]["BR_NO"].ToString() + "/" + Convert.ToDateTime(dtDet.Rows[0]["BR_DATE"]).ToString("dd/MM/yyyy"), normalFont));
                 narrationCell.Colspan = 2;
                 detailsTable.AddCell(narrationCell);
                 detailsTable.AddCell(new Phrase("", normalFont));

                 // === BR No. Row ===
                 //detailsTable.AddCell(new Phrase("BR No.", normalFont));
                 //detailsTable.AddCell(new Phrase("", normalFont));
                 //detailsTable.AddCell(new Phrase(dtDet.Rows[0]["BR_NO"].ToString() + "/" + Convert.ToDateTime(dtDet.Rows[0]["BR_DATE"]).ToString("dd/MM/yyyy"), normalFont));

                 // === Grand Total Row ===
                 PdfPCell totalCell = new PdfPCell(new Phrase("Grand Total", headerFont));
                 totalCell.HorizontalAlignment = Element.ALIGN_CENTER;
                 totalCell.Colspan = 1;
                 detailsTable.AddCell(totalCell);
                 detailsTable.AddCell(new Phrase(Math.Round(totalAmounts345).ToString("N0"), headerFont));
                 detailsTable.AddCell(new Phrase(Math.Round(totalAmounts345).ToString("N0"), headerFont));

                 // === Add table to PDF ===
                 document.Add(detailsTable);


                 //document.Add(new Paragraph("\n\n"));

                 //Paragraph Proposed = new Paragraph();
                 //Proposed.Alignment = Element.ALIGN_LEFT;
                 //Chunk linep = new Chunk("Proposed By................", headerFont);
                 //Proposed.Add(linep);
                 //Proposed.SpacingAfter = 15f;
                 //document.Add(Proposed);


                 //Paragraph rutinized = new Paragraph();
                 //rutinized.Alignment = Element.ALIGN_LEFT;
                 //Chunk lineR = new Chunk("S.Rutinized By................", headerFont);
                 //rutinized.Add(lineR);
                 //rutinized.SpacingAfter = 15f;
                 //document.Add(rutinized);


                 document.Add(new Paragraph("\n\n"));

                 PdfPTable signatureTable = new PdfPTable(3);
                 signatureTable.WidthPercentage = 100;





                 PdfPCell nameCell = new PdfPCell(new Phrase("Sr.Assistant", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 10f, Font.BOLD)));
                 nameCell.Border = PdfPCell.NO_BORDER;
                 nameCell.HorizontalAlignment = Element.ALIGN_CENTER;
                 signatureTable.AddCell(nameCell);



                 PdfPCell nameCell1 = new PdfPCell(new Phrase("Asst.Account Officer", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 10f, Font.BOLD)));
                 nameCell1.Border = PdfPCell.NO_BORDER;
                 nameCell1.HorizontalAlignment = Element.ALIGN_CENTER;
                 signatureTable.AddCell(nameCell1);


                 PdfPCell nameCell2 = new PdfPCell(new Phrase("Account Officer", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 10f, Font.BOLD)));
                 nameCell2.Border = PdfPCell.NO_BORDER;
                 nameCell2.HorizontalAlignment = Element.ALIGN_CENTER;
                 signatureTable.AddCell(nameCell2);


                 PdfPCell designationCell = new PdfPCell(new Phrase("PTC Section Hubballi", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 9f, Font.ITALIC)));
                 designationCell.Border = PdfPCell.NO_BORDER;
                 designationCell.HorizontalAlignment = Element.ALIGN_CENTER;
                 signatureTable.AddCell(designationCell);

                 PdfPCell designationCell1 = new PdfPCell(new Phrase("PTC Section Hubballi", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 9f, Font.ITALIC)));
                 designationCell1.Border = PdfPCell.NO_BORDER;
                 designationCell1.HorizontalAlignment = Element.ALIGN_CENTER;
                 signatureTable.AddCell(designationCell1);



                 PdfPCell designationCel2 = new PdfPCell(new Phrase("PTC Section Hubballi", FontFactory.GetFont(FontFactory.TIMES_ROMAN, 9f, Font.ITALIC)));
                 designationCel2.Border = PdfPCell.NO_BORDER;
                 designationCel2.HorizontalAlignment = Element.ALIGN_CENTER;
                 signatureTable.AddCell(designationCel2);

                 document.Add(signatureTable);
                 document.Add(new Paragraph("\n"));

                 Paragraph sys = new Paragraph("This is System Generated Signature is not Required                            Generated On  " + DateTime.Now, normalFont);
                 sys.Alignment = Element.ALIGN_CENTER;
                 document.Add(sys);


                 document.Close();

                 string company = comName;
                 string companyName = company.Trim();
                 companyName = companyName.Replace("/", "_").Replace("\\", "_");

                 byte[] bytes = memoryStream.ToArray();
                 string fname = companyName + DateTime.Now.ToString("yyyy-MM-dd-HH-mm-ss") + ".pdf";
                 string directoryPath = @"D:\PPA";
                 string filePath = Path.Combine(directoryPath, fname);
                 Directory.CreateDirectory(directoryPath);

                 using (FileStream fs = new FileStream(filePath, FileMode.Create, FileAccess.Write))
                 {
                     fs.Write(bytes, 0, bytes.Length);
                 }

                 string filename = fname;
                 string filename1 = filename;
                 string directory = @"D:\PPA";

                 string fullPath = SearchFile(directory, filename1);
                 if (File.Exists(fullPath))
                 {
                     string fl = filename.Replace(" ", "");
                     if (filename.Contains(".pdf"))
                     {
                         SavePdfToSolutionFolder(filename, fullPath);
                         Page.ClientScript.RegisterStartupScript(this.GetType(), "func",
                             "window.open('Files/" + "REGULAR" + "/" + filename + "', '_new', 'top=10,left=300,resizable=1,height=600,width=740, scrollbars=1, status=yes'); DeleteGenPdfFile();", true);
                         string localpath = Server.MapPath(@"/Files/REGULAR/" + filename);
                         Session["Path"] = localpath;
                     }
                     else
                     {
                         Response.ContentType = "application/octet-stream";
                         Response.AddHeader("Content-disposition", "attachment;filename=" + fl);
                         Response.TransmitFile(Path.Combine(directory, Session["frid"].ToString(), filename));
                     }
                 }
                 else
                 {
                     ClientScript.RegisterStartupScript(GetType(), "hwa", "swal('No File Exists', '', 'error');", true);
                 }

             }
         }
         catch (Exception Ex)
         {

         }
     }*/
    private decimal GetDecimal(string value)
    {
        decimal result = 0;
        if (!string.IsNullOrEmpty(value))
        {
            decimal.TryParse(value, out result);
        }
        return result;
    }
    static string SearchFile(string directory, string filename)
    {
        try
        {
            if (Directory.Exists(directory))
            {
                string[] files = Directory.GetFiles(directory, filename);
                if (files.Length > 0)
                {
                    return files[0];
                }

                string[] subdirectories = Directory.GetDirectories(directory);
                foreach (string subdir in subdirectories)
                {
                    string fullPath = SearchFile(subdir, filename);
                    if (fullPath != null)
                    {
                        return fullPath;
                    }
                }
            }
            else
            {

            }
        }
        catch (Exception ex)
        {

        }

        return null;
    }
    [System.Web.Services.WebMethod]
    public static string DeleteFiles()
    {
        String Path = System.Web.HttpContext.Current.Session["Path"].ToString();
        Thread.Sleep(1000);
        if (File.Exists(Path))
        {
            File.Delete(Path);
        }
        return "";
    }
    protected void SavePdfToSolutionFolder(String fileName, String FullPath)
    {
        string sourceFilePath = @"" + FullPath;
        string destinationFolderPath = Server.MapPath("~/Files/REGULAR/");
        if (!Directory.Exists(destinationFolderPath))
        {
            Directory.CreateDirectory(destinationFolderPath);
        }
        string destinationFilePath = Path.Combine(destinationFolderPath, fileName);
        try
        {
            if (System.IO.File.Exists(destinationFilePath))
            {
                File.Delete(destinationFilePath);
            }
            File.Copy(sourceFilePath, destinationFilePath, true);
        }
        catch (Exception ex)
        {

        }
    }
   /* private PdfPCell CreateBorderedCell(string text, Font font)
    {
        PdfPCell cell = new PdfPCell(new Phrase(text, font));
        cell.Border = PdfPCell.BOX;
        cell.Padding = 4f;
        return cell;
    }*/
    public static string ConvertNumberToWords(decimal number)

    {

        if (number == 0)

            return "Zero";

        string words = "";

        if (number < 0)

        {

            words = "Minus ";

            number = Math.Abs(number);

        }

        string[] unitsMap = { "Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten",

        "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen" };

        string[] tensMap = { "Zero", "Ten", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety" };

        long intPortion = (long)Math.Floor(number);

        int decimalPortion = (int)((number - intPortion) * 100);

        if (intPortion > 0)

        {

            words += ConvertToIndianCurrencyWords(intPortion);

        }

        if (decimalPortion > 0)

        {

            words += " and " + ConvertToIndianCurrencyWords(decimalPortion) + " Paise";

        }

        return words.Trim() + " Only";

    }
    private static string ConvertToIndianCurrencyWords(long number)

    {

        if (number == 0)

            return "";

        string[] ones = { "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten",

        "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen" };

        string[] tens = { "", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety" };

        string result = "";

        if ((number / 10000000) > 0)

        {

            result += ConvertToIndianCurrencyWords(number / 10000000) + " Crore ";

            number %= 10000000;

        }

        if ((number / 100000) > 0)

        {

            result += ConvertToIndianCurrencyWords(number / 100000) + " Lakh ";

            number %= 100000;

        }

        if ((number / 1000) > 0)

        {

            result += ConvertToIndianCurrencyWords(number / 1000) + " Thousand ";

            number %= 1000;

        }

        if ((number / 100) > 0)

        {

            result += ConvertToIndianCurrencyWords(number / 100) + " Hundred ";

            number %= 100;

        }

        if (number > 0)

        {

            if (number < 20)

                result += ones[number];

            else

            {

                result += tens[number / 10];

                if ((number % 10) > 0)

                    result += " " + ones[number % 10];

            }

        }

        return result.Trim();

    }



    /*protected void txtLetterNo_TextChanged(object sender, EventArgs e)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(txtLetterNo.Text))
            {
                msg.ShowWarningMessage("Enter the Letter No");
                return;
            }

            if (string.IsNullOrWhiteSpace(txtMonth.Text))
            {
                msg.ShowWarningMessage("Select Month-Year");
                return;
            }
            DateTime selectedDate;
            bool isValidDate = DateTime.TryParseExact(
                txtMonth.Text.Trim(),
                "MMM-yyyy",
                System.Globalization.CultureInfo.InvariantCulture,
                System.Globalization.DateTimeStyles.None,
                out selectedDate);

            if (!isValidDate)
            {
                msg.ShowWarningMessage("Invalid Month-Year format");
                return;
            }

            string Frommonthyer, Tomontyear;
            if (selectedDate.Month >= 4)
            {
                Frommonthyer = "04" + selectedDate.Year.ToString();
                Tomontyear = "03" + (selectedDate.Year + 1).ToString();
            }
            else
            {
                Frommonthyer = "04" + (selectedDate.Year - 1).ToString();
                Tomontyear = "03" + selectedDate.Year.ToString();
            }

            Param[0] = txtLetterNo.Text.Trim();
            Param[1] = ESCOM;
            Param[2] = Frommonthyer;
            Param[3] = Tomontyear;

            PName[0] = "@LETERNO";
            PName[1] = "@ESCOM";
            PName[2] = "@FROMMONTHYEAR";
            PName[3] = "@TOMONTHYEAR";

            Count = 4;

            DataTable CheckLeterNo = SqlCmd.SelectData("SP_CHECKLETERNO_Q1", Param, PName, Count);

            if (CheckLeterNo.Rows.Count > 0 && CheckLeterNo.Rows[0]["ExistsFlag"].ToString() == "1")
            {
                msg.ShowWarningMessage("Letter No already exists!");
                txtLetterNo.Focus();
                return;
            }
        }
        catch (Exception ex)
        {

        }
    }*/


    [WebMethod]
    public static object CheckLetterNo(string letterNo, string month)
    {
        try
        {

            if (string.IsNullOrWhiteSpace(letterNo))
            {
                return new { success = false, message = "Enter the Letter No" };
            }

            if (string.IsNullOrWhiteSpace(month))
            {
                return new { success = false, message = "Select Month-Year" };
            }

            DateTime selectedDate;
            bool isValidDate = DateTime.TryParseExact(
                month.Trim(),
                "MMM-yyyy",
                System.Globalization.CultureInfo.InvariantCulture,
                System.Globalization.DateTimeStyles.None,
                out selectedDate);

            string escomValue = HttpContext.Current.Session["ESCOM_NAME"] != null
                   ? HttpContext.Current.Session["ESCOM_NAME"].ToString()
                   : "";

            if (!isValidDate)
            {
                return new { success = false, message = "Invalid Month-Year format" };
            }

            string Frommonthyer, Tomontyear;
            if (selectedDate.Month >= 4)
            {
                Frommonthyer = "04" + selectedDate.Year.ToString();
                Tomontyear = "03" + (selectedDate.Year + 1).ToString();
            }
            else
            {
                Frommonthyer = "04" + (selectedDate.Year - 1).ToString();
                Tomontyear = "03" + selectedDate.Year.ToString();
            }


            string[] Param = new string[4];
            string[] PName = new string[4];

            Param[0] = letterNo.Trim();
            Param[1] = escomValue;
            Param[2] = Frommonthyer;
            Param[3] = Tomontyear;

            PName[0] = "@LETERNO";
            PName[1] = "@ESCOM";
            PName[2] = "@FROMMONTHYEAR";
            PName[3] = "@TOMONTHYEAR";

            DataTable CheckLeterNo = SqlCmd.SelectData("SP_CHECKLETERNO_Q1", Param, PName, 4);

            if (CheckLeterNo.Rows.Count > 0 && CheckLeterNo.Rows[0]["ExistsFlag"].ToString() == "1")
            {
                return new { success = false, exists = true, message = "Letter No already exists!" };
            }

            return new { success = true, exists = false, message = "Letter No is available" };
        }
        catch (Exception ex)
        {
            return new { success = false, message = ex.Message };
        }
    }

}