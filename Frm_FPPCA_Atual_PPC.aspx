<%@ Page Title="" Language="C#" MasterPageFile="~/GTDMaster.master" AutoEventWireup="true" CodeFile="Frm_FPPCA_Atual_PPC.aspx.cs" Inherits="KPCL_coal_fuelmanagement_Frm_FPPCA_Atual_PPC" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <script>
        let globalAllRows = [];
        let sectionTotalsMap = {};
        $(document).ready(function () {

            $("#dataTableContainer").hide();
            $("#yearDropdown").hide();
            loadEscoms();
            populateFinancialYears();

            $("#viewbtn").on("click", function () {
                loadPPCData();
            });

            $("#btn_Save").click(function () {
                saveSectionData();
            });

            window.addEventListener("message", function (event) {
                if (event.data.annexureTotal !== undefined) {
                    let activeBox = $(".annexure-box.active");
                    if (activeBox.length > 0) {
                        activeBox.val(event.data.annexureTotal);
                        activeBox.removeClass("active");

                        activeBox.closest("tr").find("input").first().trigger("input");
                    }
                }
            });



            $(document).on("click", ".annexure-box", function () {


                let sectionId = $(this).data("section");

                if (sectionId == "12") {

                    $(".annexure-box").removeClass("active");
                    $(this).addClass("active");

                    let stationSectionId = sectionId;

                    let row = $(this).closest("tr");
                    let fppcaId = row.find("input[data-column='FPPCAID']").val() || "0";

                    window.open(
                        `Frm_ADD_Annexure_Data.aspx?sectionId=${sectionId}&stationSectionId=${stationSectionId}&fppcaId=${fppcaId}`,
                        "_blank",
                        "width=1000,height=700"
                    );
                }
            });

        });


        function loadPPCData() {

            $("#dataTableContainer").hide();
            var escom = $("#ddlEscoms option:selected").text();
            var year = $("#yearselection").val();
            var month = $("#txtmonth").val();

            if (!escom || !month) {
                showWarningMessage("Please Select All The Fields");
                return;
            }

            $.ajax({
                type: "POST",
                url: "Frm_FPPCA_Atual_PPC.aspx/GetPPCData",
                data: JSON.stringify({ escom: escom, year: year, month: month }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (response) {
                    var res = response.d;
                    $("#dataTableContainer").empty();

                    if (res.HasData) {
                        $("#dataTableContainer").show();
                        for (let sectionId in res.Sections) {
                            const sectionData = res.Sections[sectionId];
                            const sectionName = res.SectionNames[sectionId] || "Unnamed Section";

                            let sectionHtml = `
                        <div class="card mb-3 p-2 border border-2 border-secondary rounded">
                            <h6 class="text-primary fw-bold">Section: ${sectionName}</h6>
                            <div class="table-responsive">
                                <table class="table table-striped table-bordered text-center mb-2" id="table_${sectionId}">
                                    <thead></thead>
                                    <tbody></tbody>
                                </table>
                            </div>
                            <div class="text-end">
                                <button type="button" class="btn btn-sm btn-danger save-section-btn" 
                                    data-section="${sectionId}">Save Section</button>
                            </div>
                        </div>
                        <div style="height:15px;"></div>
                    `;

                            $("#dataTableContainer").append(sectionHtml);
                            bindSectionTable(sectionId, sectionData);
                        }

                        $(".save-section-btn").off("click").on("click", function () {
                            let sectionId = $(this).data("section");
                            saveSectionData(sectionId);
                        });
                    } else {
                        $("#dataTableContainer").html("<div class='alert alert-warning'>No data found.</div>");
                    }
                },
                error: function (xhr, status, error) {
                    console.error("Error:", error);
                    $("#dataTableContainer").html("<div class='alert alert-danger'>Error loading data.</div>");
                }
            });
        }


        function bindSectionTable(sectionId, data) {

            if (!data || data.length === 0) return;

            const editableColumns = [
                "Capacity Charges for the Month",
                "Quantum of energy Purchased in the month",
                "Variable Charges1 (Rs./unit)",
                "Variable Charges (Rs.in Cr.)"
            ];

            const readOnlyColumns = [
                "Capacity Charges Per Month",
                "Variable Charges (Rs./unit)"
            ];

            const hiddenColumns = [
                "RCPTDATE", "BILLDATE", "NME", "CC", "PEC", "SEC", "RC",
                "VAMT", "PERC", "ALLOCATED"
            ];

            const cols = Object.keys(data[0]);
            let thead = "<tr>";

            cols.forEach(c => {
                if (c === "FPPCAID" || hiddenColumns.includes(c)) {
                    thead += `<th style="display:none">${c}</th>`;
                } else {
                    thead += `<th style="border: 1px solid #dee2e6;">${c}</th>`;
                }
            });

            thead += "</tr>";
            $(`#table_${sectionId} thead`).html(thead);

            let tbody = "";

            data.forEach(row => {

                const ssid = row["STATION_SECTION_ID"] ?? row["Station_Section_Id"] ?? row["STATION_SECTION_Id"] ?? "";
                tbody += `<tr data-ssid='${ssid}'>`;

                if (typeof globalAllRows !== "undefined" && Array.isArray(globalAllRows)) {
                    globalAllRows.push(row);
                }

                cols.forEach(c => {

                    if (c === "FPPCAID" || hiddenColumns.includes(c)) {
                        tbody += `<td style="display:none"><input type='hidden' data-column='${c}' value='${row[c] ?? ""}' /></td>`;
                        return;
                    }

                    const isEditableSection = (sectionId == "6"||sectionId == "7"||sectionId == "8" || sectionId == "9"||sectionId == "10" || sectionId == "11");

                    if (readOnlyColumns.includes(c)) {

                        if (isEditableSection) {
                            tbody += `<td style="border: 1px solid #dee2e6;">
                        <input type='text' class='form-control form-control-sm text-center'
                        data-column='${c}' value='${row[c] ?? "0"}' style='border: 2px solid #007bff;' />
                    </td>`;
                        } else {
                            tbody += `<td style="border: 1px solid #dee2e6;">
                        <input type='text' class='form-control form-control-sm text-center'
                        data-column='${c}' value='${row[c] ?? "0"}' readonly />
                    </td>`;
                        }
                        return;
                    }

                    if (c === "Variable Charges (Rs.in Cr.)") {
                        if (sectionId == "12") {
                            tbody += `<td style="border: 1px solid #dee2e6;">
                        <input type='text' class='form-control form-control-sm text-center annexure-box'
                        data-column='${c}' data-section='${sectionId}' value='${row[c] ?? "0"}' readonly />
                    </td>`;
                        } else {
                            tbody += `<td style="border: 1px solid #dee2e6;">
                        <input type='text' class='form-control form-control-sm text-center'
                        data-column='${c}' value='${row[c] ?? "0"}' style='border: 2px solid #007bff;' />
                    </td>`;
                        }
                        return;
                    }

                    if (editableColumns.includes(c)) {
                        tbody += `<td style="border: 1px solid #dee2e6;">
                    <input type='text' class='form-control form-control-sm text-center'
                    data-column='${c}' value='${row[c] ?? "0"}' style='border: 2px solid #007bff;' />
                </td>`;
                        return;
                    }

                    if (c === "Total Power Purchase cost paid for the month" ||
                        c === "Difference in power Purchase cost for the month") {

                        tbody += `<td data-col='${c}' style="border: 1px solid #dee2e6;">
                    ${row[c] ?? "0"}
                </td>`;
                        return;
                    }

                    tbody += `<td style="border: 1px solid #dee2e6;">${row[c] ?? ""}</td>`;

                });

                tbody += "</tr>";
            });

            $(`#table_${sectionId} tbody`).html(tbody);

            attachRowFormula(sectionId);
            addSectionTotal(sectionId, cols);

            if (sectionId == "10" || sectionId == "11" || sectionId == "12") {
                addGrandTotal(cols, parseInt(sectionId, 10));
            }

            if (sectionId == "12") {

                addGrandTotal(cols, 12);

                let finalGrandTotal = getGrandTotalForSection12(cols);

                console.log("FINAL GRAND TOTAL FOR SECTION 12:", finalGrandTotal);

                saveGrandTotalSection12(finalGrandTotal);
            }

            $(`#table_${sectionId} tbody input`).on("focus", function () {
                if ($(this).val().trim() === "0") $(this).val("");
            });

            $(`#table_${sectionId} tbody input`).on("blur", function () {
                if ($(this).val().trim() === "") $(this).val("0");
            });

            $(`#table_${sectionId} tbody input`).on("input", function () {
                recalcAll(sectionId, cols);
            });

            $(`#table_${sectionId} tbody`).on("click", "input", function () {
                recalcAll(sectionId, cols);
            });

            $(`#table_${sectionId} tbody`).on("click", "td", function () {
                recalcAll(sectionId, cols);
            });


        }




        function attachRowFormula(sectionId) {
            let table = $(`#table_${sectionId}`);

            function getValue(row, col) {
                let input = row.find(`input[data-column='${col}']`);
                if (input.length) {
                    return parseFloat(input.val()) || 0;
                }
                let td = row.find(`td[data-col='${col}']`);
                if (td.length) return parseFloat(td.text()) || 0;
                return 0;
            }

            function calculateRow(row) {
                let capPerMonth = getValue(row, "Capacity Charges Per Month");
                let varChgPerUnit = getValue(row, "Variable Charges (Rs./unit)");
                let SCC = getValue(row, "Capacity Charges for the Month");
                let SNME = getValue(row, "Quantum of energy Purchased in the month");
                let ECR = getValue(row, "Variable Charges1 (Rs./unit)");
                let SAMT = getValue(row, "Variable Charges (Rs.in Cr.)");

                let totalCost = SCC + SAMT;
                let diffCost = totalCost - (capPerMonth + (varChgPerUnit * SNME / 10));

                row.find("td[data-col='Total Power Purchase cost paid for the month']").text(totalCost.toFixed(2));
                row.find("td[data-col='Difference in power Purchase cost for the month']").text(diffCost.toFixed(2));
            }

            table.find("tbody tr").each(function () { calculateRow($(this)); });
            table.find("input").off("input.attachFormula").on("input.attachFormula", function () { calculateRow($(this).closest("tr")); });
        }


        function addSectionTotal(sectionId, cols) {

            const table = $(`#table_${sectionId}`);
            const rows = table.find("tbody tr");

            let totals = {};

            cols.forEach(c => {
                if (!isHiddenColumn(c) && !isTextColumn(c))  
                    totals[c] = 0;
            });

            rows.each(function () {
                let r = $(this);

                if (r.hasClass("section-total-row") || r.hasClass("grand-total-row")) return;

                cols.forEach(c => {

                    if (isHiddenColumn(c) || isTextColumn(c)) return; // <-- skip

                    let val = 0;

                    if (isFormulaColumn(c)) {
                        val = parseFloat(r.find(`td[data-col='${c}']`).text()) || 0;
                    } else {
                        let input = r.find(`input[data-column='${c}']`);
                        if (input.length > 0)
                            val = parseFloat(input.val()) || 0;
                        else
                            val = parseFloat(r.find(`td[data-col='${c}']`).text()) || 0;
                    }

                    totals[c] += val;
                });
            });

            sectionTotalsMap[sectionId] = totals;

            let hideRow = (sectionId == "10" || sectionId == "11" || sectionId == "12");

            let totalRow = `<tr class="section-total-row"
                        style="${hideRow ? 'display:none;' : 'background:#e9ecef; font-weight:bold;'}">`;

            cols.forEach(c => {

                if (isHiddenColumn(c)) {
                    totalRow += `<td style="display:none"></td>`;
                }
                else if (isTextColumn(c)) {
                    totalRow += `<td style="font-weight:bold;">TOTAL</td>`;   
                }
                else {
                    if (isHideInTotals(c)) {
                        totalRow += `<td></td>`; 
                    }
                    else {
                        totalRow += `<td>${(totals[c] || 0).toFixed(2)}</td>`;
                    }

                }

            });

            totalRow += "</tr>";
            table.find("tbody").append(totalRow);
        }


        function addGrandTotal(cols, currentStationSectionId) {

            $(`#table_${currentStationSectionId} tbody tr.grand-total-row`).remove();

            let grandTotals = {};

            cols.forEach(c => {
                if (!isHiddenColumn(c) && !isTextColumn(c) && !isHideInTotals(c))
                    grandTotals[c] = 0;
            });

            Object.keys(sectionTotalsMap).forEach(secId => {

                let sid = parseInt(secId);

                if (currentStationSectionId === 10 && sid > 10) return;
                if (currentStationSectionId === 11 && sid > 11) return;

                let totals = sectionTotalsMap[secId];

                cols.forEach(c => {
                    if (!isHiddenColumn(c) && !isTextColumn(c) && !isHideInTotals(c)) {
                        grandTotals[c] += (totals[c] || 0);
                    }
                });
            });

            let grandRow = `<tr class="grand-total-row" style='background:#ffc107; font-weight:bold;'>`;

            cols.forEach(c => {

                if (isHiddenColumn(c)) {
                    grandRow += `<td style='display:none'></td>`;
                }
                else if (isTextColumn(c)) {
                    grandRow += `<td><b>GRAND TOTAL</b></td>`;
                }
                else if (isHideInTotals(c)) {
                    grandRow += `<td></td>`;  
                }
                else {
                    grandRow += `<td>${(grandTotals[c] || 0).toFixed(2)}</td>`;
                }

            });

            grandRow += "</tr>";

            $(`#table_${currentStationSectionId} tbody`).append(grandRow);
        }



        function isHiddenColumn(colName) {
            const hiddenColumns = [
                "RCPTDATE", "BILLDATE", "NME", "CC", "PEC", "SEC",
                "RC", "VAMT", "PERC", "ALLOCATED", "FPPCAID"
            ];
            return hiddenColumns.includes(colName);
        }

        function isFormulaColumn(colName) {
            return (
                colName === "Total Power Purchase cost paid for the month" ||
                colName === "Difference in power Purchase cost for the month"
            );
        }
        function isTextColumn(colName) {
            return colName === "Name of the Generating Station";
        }
        function isHideInTotals(colName) {
            return (
                colName === "Variable Charges (Rs./unit)" ||
                colName === "Variable Charges1 (Rs./unit)"
            );
        }


        function getGrandTotalForSection12(cols) {
            debugger;
            let table = $("#table_12");
            let grandRow = table.find("tbody tr.grand-total-row");

            if (grandRow.length === 0) return null; 

            let grandTotalObj = {};

            cols.forEach(c => {

                if (isHiddenColumn(c)) return;

                if (isTextColumn(c)) {
                    grandTotalObj[c] = "GRAND TOTAL";
                    return;
                }

                if (isHideInTotals(c)) {
                    grandTotalObj[c] = ""; 
                    return;
                }

                let td = grandRow.find("td").eq(cols.indexOf(c));
                let val = parseFloat(td.text()) || 0;
                grandTotalObj[c] = val;
            });

            return grandTotalObj;
        }

        function saveGrandTotalSection12(grandTotal) {

            let type = $("#ddltype").val() || "";
            let Escom =$("#ddlEscoms option:selected").text();
            let Month = $("#txtmonth").val() || "";
            debugger;
            $.ajax({
                type: "POST",
                url: "Frm_FPPCA_Atual_PPC.aspx/SaveGrandTotalSection12",
                data: JSON.stringify({ grandTotal: grandTotal, Month: Month, Escom: Escom, type: type }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (res) {
                    console.log("Grand Total Saved Successfully!", res);
                },
                error: function (err) {
                    console.error("Error Saving Grand Total", err);
                }
            });
        }


        function recalcAll(sectionId, cols) {

            attachRowFormula(sectionId);

            $(`#table_${sectionId} tbody tr.section-total-row`).remove();
            $(`#table_${sectionId} tbody tr.grand-total-row`).remove();

            addSectionTotal(sectionId, cols);

            addGrandTotal(cols, 10);
            addGrandTotal(cols, 11);
            addGrandTotal(cols, 12);

            let finalGrandTotal = getGrandTotalForSection12(cols);
            saveGrandTotalSection12(finalGrandTotal);
        }




        function saveSectionData(sectionId) {

            let table = $(`#table_${sectionId}`);
            let rowsData = [];

            table.find("tbody tr").each(function () {
                let row = $(this);
                let rowData = {};

                row.find("td").each(function () {
                    let input = $(this).find("input");
                    let col = input.data("column") || $(this).data("col");
                    if (!col) return;

                    let val = "0";

                    if (input.length > 0) {
                        val = input.val();
                    } else {
                        val = $(this).text().trim(); 
                    }

                    if (val === "" || val === undefined || val === null) val = "0";

                    rowData[col] = val;
                });

                let fppcaIdInput = row.find("input[data-column='FPPCAID']");
                rowData["FPPCAID"] = fppcaIdInput.length ? (fppcaIdInput.val() || "0") : "0";

                rowsData.push(rowData);
            });


            let escom = $("#ddlEscoms").val() || "";
            let year = $("#yearselection").val() || "";
            let month = $("#txtmonth").val() || "";
            let type = $("#ddltype").val() || "";

            if (!escom || !month) {
                alert("Please select all the fields.");
                return;
            }

            $.ajax({
                type: "POST",
                url: "Frm_FPPCA_Atual_PPC.aspx/SavePPCData",
                data: JSON.stringify({
                    escom: escom,
                    year: year,
                    month: month,
                    data: rowsData,
                    sectionId: sectionId,
                    type: type
                }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (res) {
                    if (res.d && typeof res.d === "string" && res.d.includes("DATA EXIST")) {
                        alert(res.d);
                    } else {
                        showSuccessMessage("Data Saved Successfully");
                    }
                },
                error: function (err) {
                    console.error(err);
                    alert("Error saving data.");
                }
            });
        }


        function populateFinancialYears() {
            const currentYear = new Date().getFullYear();
            const currentMonth = new Date().getMonth() + 1;
            let startYear = currentMonth >= 4 ? currentYear : currentYear - 1;
            const yearSelect = $('#yearselection');
            yearSelect.empty();

            for (let i = -5; i <= 2; i++) {
                const fyStartYear = startYear + i;
                const fyEndYear = fyStartYear + 1;
                const fyValue = `${fyStartYear}-${fyEndYear.toString().slice(-2)}`;
                const fyText = `${fyStartYear}-${fyEndYear}`;
                const isSelected = i === 0 ? 'selected' : '';
                yearSelect.append(`<option value="${fyValue}" ${isSelected}>${fyText}</option>`);
            }
        }

       
        $(document).on("keypress", "input[type='text']", function (e) {

            if (
                e.which !== 8 &&
                e.which !== 9 &&
                e.which !== 46 &&
                e.which !== 45 &&               
                (e.which < 37 || e.which > 40) &&
                (e.which < 48 || e.which > 57) &&
                e.which !== 46
            ) {
                e.preventDefault();
            }

            if (e.which === 45 && this.selectionStart !== 0) {
                e.preventDefault();
            }
        });




        function loadEscoms() {
            $.ajax({
                type: "POST",
                url: "Frm_FPPCA_Atual_PPC.aspx/GetEscoms",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (response) {
                    var data = response.d;
                    var ddl = $("#ddlEscoms");
                    ddl.empty();
                    ddl.append('<option value="">-- Select Escom --</option>');

                    $.each(data, function (i, item) {
                        ddl.append($('<option>', { value: item.CMID, text: item.CMNAME }));
                    });
                },
                error: function (xhr, status, error) { console.error("Error loading ESCOMs:", error); }
            });
        }
    </script>


</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="Server">
    <div class="container-fluid">

        <div class="card mt-4">
            <div class="card-header">
                FPPCA Validation & Correction
            </div>
            <div class="card-body">
                <div class="row">
                    <div class="col-md-3 mb-3">
                        <label class="form-label">Select Month-Year:<span class="text-danger">*</span></label>
                        <div class="input-group">
                            <input type="text" id="txtmonth" onkeydown="false" class="form-control datepicker-pick-level_Month_Default_PastMonth" placeholder="MM-YYYY" />
                        </div>
                    </div>

                    <div class="col-md-3" id="account_Head2">
                        <label class="form-label">Escoms : </label>
                        <span class="text-danger">*</span>
                        <select id="ddlEscoms" class="form-select" style="height: 40px;">
                            <option value="">-- Select Escom --</option>
                        </select>
                    </div>


                    <div class="col-md-3">
                        <label class="form-label">Types :</label>
                        <span class="text-danger">*</span>
                        <select id="ddltype" class="form-select" style="height: 40px;">
                            <option value="">-- Select Type --</option>
                            <option value="0">Format-1 Adjustment</option>
                            <option value="1">Format-1 Filing</option>
                        </select>
                    </div>

                    <div class="col-md-3" id="yearDropdown">
                        <label class="form-label fw-bold">
                            <i class="ph-calendar"></i>Financial Year
                        </label>
                        <select class="form-select mt-2" id="yearselection">
                            <option value="">Select Year</option>
                        </select>
                    </div>

                    <div class="text-left col-md-3 mt-4">
                        <button type="button" id="viewbtn" class="btn btn-info">View</button>
                    </div>

                    <div class="card ms-2 me-2 mt-4" id="dataTableContainer">
                        <div class="card-header">
                            <div class="row justify-content-between align-items-center">
                                <h5 class="mb-0 col-xs-12 col-sm-5 col-lg-8 col-xl-8"></h5>
                                <div class="col-xs-12 col-sm-7 col-lg-4 col-xl-4 button-custom-alignment text-end">
                                    <button id="Excelbtn" type="button" class="btn btn-success btn-sm me-2">
                                        <i class="ph ph-file-xls me-1 fs-lg"></i>Excel
                                    </button>

                                    <button id="pdfbtn" type="button" class="btn btn-danger btn-sm">
                                        <i class="ph ph-file-pdf me-1 fs-lg"></i>PDF
                                    </button>
                                </div>
                            </div>
                        </div>
                        <div class="card-body">
                            <div class="table-responsive table-container">
                                <table id="readingTable" class="table table-striped table-bordered text-center">
                                    <thead id="dataTableHeader"></thead>
                                    <tbody id="dataTableBody"></tbody>
                                    <tfoot id="dataTableFooter"></tfoot>
                                </table>
                            </div>
                            <div class="text-center mt-3">
                                <button id="btn_Save" type="button" class="btn btn-danger btn-sm">
                                    <i class="ph me-1 fs-lg"></i>Save
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

    </div>

</asp:Content>

