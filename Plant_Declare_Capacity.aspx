<%@ Page Title="" Language="C#" MasterPageFile="~/GTDMaster.master" AutoEventWireup="true" CodeFile="Plant_Declare_Capacity.aspx.cs" Inherits="Plant_Declare_Capacity" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
   
    
    <script>
        let hot = null;

        $(document).ready(function () {
            Get_Gen_Name();

            $("#viewbtn").on("click", function () {
                Load_Data();
            });

            $("#Pdfbtn").on("click", function () {
                Export_PDF();
            });

            $("#Excelbtn").on("click", function () {
                Export_Excel();
            });
        });

        function Load_Data() {
            var container = document.getElementById('divDatakpcl');

            if (hot) {
                hot.destroy();
                hot = null;
            }

            var oldFooter = document.getElementById('handsonFooter');
            if (oldFooter) {
                oldFooter.remove();
            }

            var Month = $("#txtmonth").val();
            var ProjId = $("#ddl_ProjNm").val();

            if (!Month || !ProjId) {
                showWarningmessage("!Select Required Fields");
                $("#hideview").hide();
                return;
            }

            $.ajax({
                url: "Plant_Declare_Capacity.aspx/Get_Schedule_Details",
                type: "POST",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                data: JSON.stringify({ Month: Month, ProjId: ProjId }),
                success: function (res) {
                    var data = JSON.parse(res.d);

                    if (!data || data.length === 0 ||
                        (typeof data === "string" && (data === "NO_DATA" || data === "ERROR" || data.startsWith("ERROR")))) {
                        showWarningmessage("!Data Not Found");
                        $("#hideview").hide();
                        return;
                    }

                    $("#hideview").show();

                    let totalDc = 0;
                    let totalEnt = 0;

                    data.forEach(function (r, i) {
                        r.slno = i + 1;
                        r.dc_sch = Number(r.dc_sch || 0);
                        r.ent_sch = Number(r.ent_sch || 0);
                        totalDc += r.dc_sch;
                        totalEnt += r.ent_sch;
                    });

                    data.push({
                        slno: '',
                        schdate: '',
                        genname: 'TOTAL',
                        dc_sch: totalDc,
                        ent_sch: totalEnt
                    });

                    hot = new Handsontable(container, {
                        data: data,
                        mergeCells: [
                            { row: data.length - 1, col: 0, rowspan: 1, colspan: 3 }
                        ],
                        colHeaders: [
                            'Sl No',
                            'Schedule Date',
                            'Generator Name',
                            'Declaration Schedule',
                            'Entitlement Schedule'
                        ],
                        columns: [
                            {
                                data: 'slno',
                                className: 'htCenter',
                                readOnly: true,
                                width: 80,
                                renderer: function (instance, td, row, col, prop, value, cellProperties) {
                                    Handsontable.dom.empty(td);
                                    if (row === data.length - 1) {
                                        td.textContent = 'TOTAL';
                                        td.style.fontWeight = 'bold';
                                        td.style.backgroundColor = '#f2f2f2';
                                        td.style.textAlign = 'center';
                                    } else {
                                        td.textContent = value;
                                    }
                                    td.className = 'htCenter';
                                    return td;
                                }
                            },
                            {
                                data: 'schdate',
                                className: 'htCenter',
                                readOnly: true,
                                width: 120,
                                renderer: function (instance, td, row, col, prop, value, cellProperties) {
                                    Handsontable.dom.empty(td);
                                    if (value) {
                                        td.textContent = new Date(value).toLocaleDateString('en-GB');
                                    }
                                    td.className = 'htCenter';
                                    return td;
                                }
                            },
                            {
                                data: 'genname',
                                className: 'htCenter',
                                readOnly: true,
                                width: 200
                            },
                            {
                                data: 'dc_sch',
                                type: 'numeric',
                                className: 'htCenter',
                                readOnly: true,
                                width: 150,
                                numericFormat: {
                                    pattern: '0,0.00'
                                },
                                renderer: function (instance, td, row, col, prop, value, cellProperties) {
                                    Handsontable.dom.empty(td);
                                    if (row === data.length - 1) {
                                        td.style.fontWeight = 'bold';
                                        td.style.backgroundColor = '#f2f2f2';
                                    }
                                    td.textContent = value ? value.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) : '0.00';
                                    td.className = 'htCenter';
                                    return td;
                                }
                            },
                            {
                                data: 'ent_sch',
                                type: 'numeric',
                                className: 'htCenter',
                                readOnly: true,
                                width: 150,
                                numericFormat: {
                                    pattern: '0,0.00'
                                },
                                renderer: function (instance, td, row, col, prop, value, cellProperties) {
                                    Handsontable.dom.empty(td);
                                    if (row === data.length - 1) {
                                        td.style.fontWeight = 'bold';
                                        td.style.backgroundColor = '#f2f2f2';
                                    }
                                    td.textContent = value ? value.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) : '0.00';
                                    td.className = 'htCenter';
                                    return td;
                                }
                            }
                        ],
                        licenseKey: 'non-commercial-and-evaluation',
                        stretchH: 'all',
                        height: 400
                    });
                },
                error: function (xhr) {
                    console.log("Error:", xhr.responseText);
                    showWarningmessage("!Error loading data");
                }
            });
        }

        function Export_PDF() {
            var Month = $("#txtmonth").val();
            var ProjId = $("#ddl_ProjNm").val();

            if (!Month || !ProjId) {
                showWarningmessage("!Select Required Fields");
                return;
            }

            $.ajax({
                url: "Plant_Declare_Capacity.aspx/GeneratePDF",
                type: "POST",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                data: JSON.stringify({ Month: Month, ProjId: ProjId }),
                success: function (res) {
                    var base64 = res.d;

                    if (!base64 || base64 === "NO_DATA") {
                        showWarningmessage("!Data Not Found");
                        return;
                    }

                    if (base64 === "ERROR" || base64.startsWith("Error")) {
                        showWarningmessage("!Error generating PDF");
                        return;
                    }

                    var byteCharacters = atob(base64);
                    var byteNumbers = new Array(byteCharacters.length);

                    for (var i = 0; i < byteCharacters.length; i++) {
                        byteNumbers[i] = byteCharacters.charCodeAt(i);
                    }

                    var blob = new Blob([new Uint8Array(byteNumbers)], { type: "application/pdf" });
                    var link = document.createElement("a");

                    link.href = window.URL.createObjectURL(blob);
                    link.download = "Plant_Declare_Capacity_" + Month + ".pdf";
                    document.body.appendChild(link);
                    link.click();
                    document.body.removeChild(link);

                    showSuccessmessage("PDF downloaded successfully!");
                },
                error: function () {
                    showWarningmessage("!PDF generation failed");
                }
            });
        }

        function Export_Excel() {
            var Month = $("#txtmonth").val();
            var ProjId = $("#ddl_ProjNm").val();

            if (!Month || !ProjId) {
                showWarningmessage("!Select Required Fields");
                return;
            }

            $.ajax({
                url: "Plant_Declare_Capacity.aspx/GenerateExcel",
                type: "POST",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                data: JSON.stringify({ Month: Month, ProjId: ProjId }),
                success: function (res) {
                    var base64 = res.d;

                    if (!base64 || base64 === "NO_DATA") {
                        showWarningmessage("!Data Not Found");
                        return;
                    }

                    if (base64 === "ERROR" || base64.startsWith("Error")) {
                        showWarningmessage("!Error generating Excel");
                        return;
                    }

                    var byteChars = atob(base64);
                    var byteNumbers = new Array(byteChars.length);

                    for (var i = 0; i < byteChars.length; i++) {
                        byteNumbers[i] = byteChars.charCodeAt(i);
                    }

                    var blob = new Blob(
                        [new Uint8Array(byteNumbers)],
                        { type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }
                    );

                    var link = document.createElement("a");
                    link.href = URL.createObjectURL(blob);
                    link.download = "PLANT_DECLARE_CAPACITY_" + Month + ".xlsx";
                    document.body.appendChild(link);
                    link.click();
                    document.body.removeChild(link);

                    showSuccessmessage("Excel downloaded successfully!");
                },
                error: function () {
                    showWarningmessage("!Excel generation failed");
                }
            });
        }

        function Get_Gen_Name() {
            $.ajax({
                url: "Plant_Declare_Capacity.aspx/Get_GenName",
                type: "POST",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                data: JSON.stringify({}),
                success: function (res) {
                    var data = res.d;
                    var ddl = $("#ddl_ProjNm");
                    ddl.empty();
                    ddl.append('<option value="">-- Select STAKEHOLDERS --</option>');
                    if (data && data.length > 0) {
                        $.each(data, function (i, row) {
                            ddl.append(`<option value="${row.ID}">${row.Name}</option>`);
                        });
                    }
                },
                error: function (err) {
                    console.log(err);
                    alert("Error fetching Stakeholders!");
                }
            });
        }
    </script>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="Server">
    <div class="container-fluid">
        <div class="card">
            <div class="card-header">
                Plant Declare Capacity
            </div>
            <div class="card-body">
                <div class="row">
                    <div class="col-md-3 mb-3">
                        <label class="form-label">Select Month-Year:<span class="text-danger">*</span></label>
                        <div class="input-group">
                            <input type="text" id="txtmonth" onkeydown="return false" 
                                   class="form-control datepicker-pick-level_Month_Default_PastMonth" 
                                   placeholder="MM-YYYY" />
                        </div>
                    </div>

                    <div class="col-md-3">
                        <label class="form-label">Bill Type : <span class="text-danger">*</span></label>
                        <select id="ddl_Type" class="form-select">
                            <option value="">-- Select Bill Type --</option>
                            <option value="0">Thermal</option>
                            <option value="1">Hydro</option>
                        </select>
                    </div>

                    <div class="col-md-3">
                        <label class="form-label">ProjName : <span class="text-danger">*</span></label>
                        <select id="ddl_ProjNm" class="form-select">
                            <option value="">-- Select ProjName --</option>
                        </select>
                    </div>

                    <div class="col-md-3">
                        <label class="form-label">Units : <span class="text-danger">*</span></label>
                        <select id="ddl_Units" class="form-select">
                            <option value="">-- Select Units --</option>
                        </select>
                    </div>

                    <div class="col-md-12 d-flex justify-content-end mt-2">
                        <div class="btn-group col-md-2" role="group" aria-label="View and Download">
                            <button type="button" id="viewbtn" 
                                    class="btn btn-info flex-fill rounded-end-0">
                                View
                            </button>

                            <button type="button" 
                                    class="btn btn-secondary dropdown-toggle flex-fill rounded-start-0 ms-2"
                                    id="ddlDownload" data-bs-toggle="dropdown">
                                Download Report
                            </button>

                            <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="ddlDownload">
                                <li>
                                    <button type="button" class="dropdown-item text-danger" id="Pdfbtn">
                                        <i class="ph ph-file-pdf me-1 fs-lg"></i>PDF
                                    </button>
                                </li>
                                <li>
                                    <button type="button" class="dropdown-item text-secondary" id="Excelbtn">
                                        <i class="ph ph-file-xls me-1 fs-lg"></i>Excel
                                    </button>
                                </li>
                            </ul>
                        </div>
                    </div>

                    <div class="col-md-12 mt-3">
                        <div class="card-body" id="hideview" style="display: none;">
                            <div id="divDatakpcl"></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</asp:Content>