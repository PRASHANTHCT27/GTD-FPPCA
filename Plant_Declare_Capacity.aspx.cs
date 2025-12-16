using ClosedXML.Excel;
using iTextSharp.text;
using iTextSharp.text.pdf;
using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;

public partial class Plant_Declare_Capacity : System.Web.UI.Page
{

    static DataTable dt = new DataTable();
    static SqlCmd SqlCmd = new SqlCmd();
    static string[] Param = new string[30];
    static string[] PName = new string[30];

    protected void Page_Load(object sender, EventArgs e)
    {

    }


    public class DesignationModel
    {
        public string ID { get; set; }
        public string Name { get; set; }
    }


    [WebMethod]
    public static List<DesignationModel> Get_GenName()

    {
        List<DesignationModel> list = new List<DesignationModel>();

        /* Param[0] = ESCOM_ID;
         PName[0] = "@ESCOM_ID";*/

        DataTable dt = SqlCmd.SelectDataSchedulingMaster("SP_GET_GENERATOR_NAME", null, null, 0);

        foreach (DataRow dr in dt.Rows)
        {
            list.Add(new DesignationModel()
            {
                ID = dr["GENID"].ToString(),
                Name = dr["GENFULLNAME"].ToString()
            });
        }

        return list;
    }


    [WebMethod]
    public static string Get_Schedule_Details(string Month, string ProjId)
    {
        try
        {
            DateTime monthDate = DateTime.ParseExact(
                Month,
                "MMM-yyyy",
                CultureInfo.InvariantCulture,
                DateTimeStyles.None
            );
           

                    DateTime fromDate = new DateTime(monthDate.Year, monthDate.Month, 1);

                    Param[0] = fromDate.ToString("yyyy-MM-dd");
                    PName[0] = "@YYYY_MM";

                    Param[1] = ProjId;
                    PName[1] = "@GENID";

        

            DataTable dt = SqlCmd.SelectDataSchedulingMaster("SP_CGS_DECLARE_CAPACITY_V1",Param,PName,2);

            if (dt == null || dt.Rows.Count == 0)
            {
                return Newtonsoft.Json.JsonConvert.SerializeObject("NO_DATA");
            }

            if (dt.Rows[0][0].ToString().ToUpper().Contains("ERROR"))
            {
                return Newtonsoft.Json.JsonConvert.SerializeObject("ERROR");
            }

            return Newtonsoft.Json.JsonConvert.SerializeObject(dt);
        }
        
        catch (Exception ex)
                {
                    return "Error: " + ex.Message;
                }
            }



    [WebMethod]
    public static string GeneratePDF(string Month, string ProjId)
    {
        try
        {
            DateTime monthDate = DateTime.ParseExact(
                Month,
                "MMM-yyyy",
                CultureInfo.InvariantCulture,
                DateTimeStyles.None
            );

            DateTime fromDate = new DateTime(monthDate.Year, monthDate.Month, 1);

            string[] Param = new string[30];
            string[] PName = new string[30];

            Param[0] = fromDate.ToString("yyyy-MM-dd");
            PName[0] = "@YYYY_MM";

            Param[1] = ProjId;
            PName[1] = "@GENID";

            SqlCmd SqlCmd = new SqlCmd();
            DataTable dt = SqlCmd.SelectDataSchedulingMaster(
                "SP_CGS_DECLARE_CAPACITY_V1",
                Param,
                PName,
                2
            );

            if (dt == null || dt.Rows.Count == 0)
                return "NO_DATA";

            if (dt.Rows[0][0].ToString().ToUpper().Contains("ERROR"))
                return "ERROR";

            using (MemoryStream ms = new MemoryStream())
            {
                Document document = new Document(PageSize.A4, 25, 25, 30, 30);
                PdfWriter writer = PdfWriter.GetInstance(document, ms);

                writer.PageEvent = new PdfFooter("Transvision Software and Data Solutions pvt ltd");
                document.Open();

                document.Open();

                Font titleFont = FontFactory.GetFont("Arial", 16, Font.BOLD);
                Font headerFont = FontFactory.GetFont("Arial", 10, Font.BOLD);
                Font normalFont = FontFactory.GetFont("Arial", 9);

                Paragraph title = new Paragraph("PLANT DECLARE CAPACITY", titleFont)
                {
                    Alignment = Element.ALIGN_CENTER,
                    SpacingAfter = 10f
                };
                document.Add(title);

                Paragraph info = new Paragraph(
     "Month: " + Month + " | Generator: " + dt.Rows[0]["genname"].ToString(),
     normalFont
 );

                info.SpacingAfter = 15f;
                document.Add(info);

                PdfPTable table = new PdfPTable(5);
                table.WidthPercentage = 100;
                table.SetWidths(new float[] { 8f, 20f, 30f, 20f, 22f });

                //BaseColor headerColor = new BaseColor(173, 216, 230);
                string[] headers = {
                "Sl No",
                "Schedule Date",
                "Generator Name",
                "Declaration Schedule",
                "Entitlement Schedule"
            };

                foreach (string h in headers)
                {
                    PdfPCell cell = new PdfPCell(new Phrase(h, headerFont))
                    {
                       // BackgroundColor = headerColor,
                        HorizontalAlignment = Element.ALIGN_CENTER,
                        Padding = 6
                    };
                    table.AddCell(cell);
                }

                decimal totalDc = 0, totalEnt = 0;

                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    DataRow r = dt.Rows[i];

                    table.AddCell(new PdfPCell(new Phrase((i + 1).ToString(), normalFont)) { HorizontalAlignment = Element.ALIGN_CENTER });
                    table.AddCell(new PdfPCell(new Phrase(r["schdate"].ToString(), normalFont)) { HorizontalAlignment = Element.ALIGN_CENTER });
                    table.AddCell(new PdfPCell(new Phrase(r["genname"].ToString(), normalFont)) { HorizontalAlignment = Element.ALIGN_CENTER });

                    decimal dc = Convert.ToDecimal(r["dc_sch"]);
                    decimal ent = Convert.ToDecimal(r["ent_sch"]);

                    totalDc += dc;
                    totalEnt += ent;

                    table.AddCell(new PdfPCell(new Phrase(dc.ToString("0.00"), normalFont)) { HorizontalAlignment = Element.ALIGN_CENTER });
                    table.AddCell(new PdfPCell(new Phrase(ent.ToString("0.00"), normalFont)) { HorizontalAlignment = Element.ALIGN_CENTER });
                }

                BaseColor totalBg = BaseColor.LIGHT_GRAY;

                PdfPCell totalLabelCell = new PdfPCell(new Phrase("Total", headerFont));
                totalLabelCell.Colspan = 3;
                totalLabelCell.HorizontalAlignment = Element.ALIGN_CENTER; 
                totalLabelCell.VerticalAlignment = Element.ALIGN_MIDDLE;
                totalLabelCell.Padding = 6;
                totalLabelCell.Border = Rectangle.BOX;
                totalLabelCell.BackgroundColor = totalBg;
                table.AddCell(totalLabelCell);


                PdfPCell totalDcCell = new PdfPCell(new Phrase(totalDc.ToString("0.00"), headerFont));
                totalDcCell.HorizontalAlignment = Element.ALIGN_CENTER;
                totalDcCell.VerticalAlignment = Element.ALIGN_MIDDLE;
                totalDcCell.Padding = 6;
                totalDcCell.Border = Rectangle.BOX;
                totalDcCell.BackgroundColor = totalBg;
                table.AddCell(totalDcCell);

                PdfPCell totalEntCell = new PdfPCell(new Phrase(totalEnt.ToString("0.00"), headerFont));
                totalEntCell.HorizontalAlignment = Element.ALIGN_CENTER;
                totalEntCell.VerticalAlignment = Element.ALIGN_MIDDLE;
                totalEntCell.Padding = 6;
                totalEntCell.Border = Rectangle.BOX;
                totalEntCell.BackgroundColor = totalBg;
                table.AddCell(totalEntCell);


                document.Add(table);
                document.Close();

                byte[] pdfBytes = ms.ToArray();
                return Convert.ToBase64String(pdfBytes);
            }
        }
        catch (Exception ex)
        {
            return "Error: " + ex.Message;
        }
    }

    public class PdfFooter : PdfPageEventHelper
    {
        string _generatedBy;

        public PdfFooter(string text)
        {
            _generatedBy = text;
        }

        public override void OnEndPage(PdfWriter writer, Document doc)
        {
            PdfPTable ft = new PdfPTable(2);
            ft.TotalWidth = doc.PageSize.Width - doc.LeftMargin - doc.RightMargin;

            ft.DefaultCell.Border = Rectangle.NO_BORDER;

            PdfPCell c1 = new PdfPCell(new Phrase("Powered By: " + _generatedBy,
                new Font(Font.FontFamily.HELVETICA, 9, Font.NORMAL, BaseColor.BLACK)));
            c1.Border = Rectangle.NO_BORDER;
            c1.HorizontalAlignment = Element.ALIGN_LEFT;

            PdfPCell c2 = new PdfPCell(new Phrase("Generated On: " +
                DateTime.Now.ToString("dd-MM-yyyy HH:mm"),
                new Font(Font.FontFamily.HELVETICA, 9, Font.NORMAL, BaseColor.BLACK)));
            c2.Border = Rectangle.NO_BORDER;
            c2.HorizontalAlignment = Element.ALIGN_RIGHT;

            ft.AddCell(c1);
            ft.AddCell(c2);

            ft.WriteSelectedRows(0, -1, doc.LeftMargin, doc.BottomMargin - 5, writer.DirectContent);
        }
    }


    [WebMethod]
    public static string GenerateExcel(string Month, string ProjId)
    {
        try
        {
            DateTime monthDate = DateTime.ParseExact(
                Month,
                "MMM-yyyy",
                CultureInfo.InvariantCulture,
                DateTimeStyles.None
            );

            DateTime fromDate = new DateTime(monthDate.Year, monthDate.Month, 1);

            string[] Param = new string[30];
            string[] PName = new string[30];

            Param[0] = fromDate.ToString("yyyy-MM-dd");
            PName[0] = "@YYYY_MM";

            Param[1] = ProjId;
            PName[1] = "@GENID";

            SqlCmd SqlCmd = new SqlCmd();
            DataTable dt = SqlCmd.SelectDataSchedulingMaster(
                "SP_CGS_DECLARE_CAPACITY_V1",
                Param,
                PName,
                2
            );

            if (dt == null || dt.Rows.Count == 0)
                return "NO_DATA";

            if (dt.Rows[0][0].ToString().ToUpper().Contains("ERROR"))
                return "ERROR";

            using (XLWorkbook wb = new XLWorkbook())
            {
                var ws = wb.Worksheets.Add("PLANT DECLARE CAPACITY");

                ws.Cell(1, 1).Value = "PLANT DECLARE CAPACITY";
                ws.Range(1, 1, 1, 5).Merge();
                ws.Cell(1, 1).Style.Font.Bold = true;
                ws.Cell(1, 1).Style.Font.FontSize = 16;
                ws.Cell(1, 1).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                ws.Cell(3, 1).Value = "Month: " + Month + " | Generator: " + dt.Rows[0]["genname"].ToString();
                ws.Range(3, 1, 3, 5).Merge();
                ws.Cell(3, 1).Style.Font.Bold = true;

                string[] headers = {
                "Sl No",
                "Schedule Date",
                "Generator Name",
                "Declaration Schedule",
                "Entitlement Schedule"
            };

                for (int i = 0; i < headers.Length; i++)
                {
                    ws.Cell(5, i + 1).Value = headers[i];
                    ws.Cell(5, i + 1).Style.Font.Bold = true;
                    ws.Cell(5, i + 1).Style.Fill.BackgroundColor = XLColor.LightGray;
                    ws.Cell(5, i + 1).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
                    ws.Cell(5, i + 1).Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
                }

                int row = 6;
                decimal totalDc = 0;
                decimal totalEnt = 0;

                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    DataRow dr = dt.Rows[i];

                    ws.Cell(row, 1).Value = i + 1;
                    ws.Cell(row, 2).Value = dr["schdate"].ToString();
                    ws.Cell(row, 3).Value = dr["genname"].ToString();

                    decimal dc = Convert.ToDecimal(dr["dc_sch"]);
                    decimal ent = Convert.ToDecimal(dr["ent_sch"]);

                    ws.Cell(row, 4).Value = dc;
                    ws.Cell(row, 5).Value = ent;

                    totalDc += dc;
                    totalEnt += ent;

                    ws.Range(row, 1, row, 5).Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
                    ws.Range(row, 1, row, 5).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                    row++;
                }

                ws.Cell(row, 1).Value = "Total";
                ws.Range(row, 1, row, 3).Merge();
                ws.Cell(row, 1).Style.Font.Bold = true;
                ws.Cell(row, 1).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
                ws.Cell(row, 1).Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;

                ws.Cell(row, 4).Value = totalDc;
                ws.Cell(row, 5).Value = totalEnt;

                ws.Range(row, 1, row, 5).Style.Font.Bold = true;
                ws.Range(row, 1, row, 5).Style.Fill.BackgroundColor = XLColor.LightGray;
                ws.Range(row, 1, row, 5).Style.Border.OutsideBorder = XLBorderStyleValues.Thin;

                ws.Range(row, 4, row, 5).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
                ws.Range(row, 4, row, 5).Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;


                ws.Columns().AdjustToContents();

                using (MemoryStream ms = new MemoryStream())
                {
                    wb.SaveAs(ms);
                    return Convert.ToBase64String(ms.ToArray());
                }
            }
        }
        catch (Exception ex)
        {
            return "Error: " + ex.Message;
        }
    }
}