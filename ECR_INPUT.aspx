<%@ Page Title="" Language="C#" MasterPageFile="~/GTDMaster.master" AutoEventWireup="true" CodeFile="ECR_INPUT.aspx.cs" Inherits="CGS_ECR_INPUT" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">

    <script>
        let allowedUsers = [];
        let hasEditAccess = false;
        let loggedUserId = null;
        let currentFormula = "";
        let formulaTerms = {};
        let hot = null;

        let ecrData = [];
        let editingRowIndex = null;
        let originalRowData = null;



        $(document).ready(function () {
            $("#formulaDisplay").hide();
            $("#logview").hide();
            $("#btn_viewbtn").show();
            $("#btn_back").hide();
            $('#staticBackdrop').modal('hide');
            $("#tableContainer").hide();
            /* $("#btn_Save").hide();*/

            lockUI();

            Get_Plant_Company();

            $("#ddl_Ptype").on("change", function () {
                Get_PlantName();
            });

            initUserAccess();

            $("#btn_Add").on("click", function () {
                debugger;
                $("#ddl_Ptype").val("");
                $("#ddl_PlantName").val("");
                $("#ddl_PlantName").on("change", function () {
                    loadFormulaForPlant();
                });
                $("#formulaDisplay").hide();
                $("#btn_back").show();
                $("#Id_Section2").show();
                $("#btn_Save").show();
                $("#txt_Handson_Table").hide();
                $("#btn_Add").hide();
                $("#logview").hide();
                $("#btn_viewbtn").hide();

            });

            $("#btn_viewbtn").on("click", function () {
                debugger;
                $("#tableContainer").hide();
                $("#Id_Section2").show();
                $("#logview").show();
                $("#btn_Save").hide();
                loadExistingECRData();
            });

            $("#btn_Cancel").on("click", function () {
                clearFormulaSection();
            });

            $("#btn_Save").on("click", function () {
                saveECRData();
            });

            $("#btn_back").on("click", function () {
                $("#ddl_PlantName").off("change");
                $("#formulaDisplay").hide();
                $("#Id_Section1").show();
                $("#Id_Section2").hide();
                $("#btn_Add").show();
                $("#btn_back").hide();
                $("#btn_viewbtn").show();
                $("#txt_Handson_Table").hide();
                $("#tableContainer").hide();
            });

            $('#logview').on('click', function () {
                showLogViewModal();
            });



            /* $("#logview").on('click', function (e) {
                 e.preventDefault();
                 showLogViewModal();
             });*/

            $("#txtmonth,#ddl_Ptype,#ddl_PlantName").on("change", function () {
                $("#txt_Handson_Table").hide();

            });
        });


        function initUserAccess() {
            getUserDetails()
                .then(getAllowedUsers)
                .then(checkUserAccess)
                .catch(err => console.error("Access init error:", err));
        }

        function getUserDetails() {
            return $.ajax({
                type: 'POST',
                url: 'ECR_INPUT.aspx/getLoginUserId',
                contentType: 'application/json; charset=utf-8',
                dataType: 'json'
            }).done(res => {
                loggedUserId = Number(res.d);
            });
        }

        function getAllowedUsers() {
            return $.ajax({
                type: "POST",
                url: "ECR_INPUT.aspx/GetAllowedUserIds",
                contentType: "application/json; charset=utf-8",
                dataType: "json"
            }).done(res => {
                allowedUsers = res.d.map(Number);
                hasEditAccess = allowedUsers.includes(loggedUserId);
            });
        }

        function checkUserAccess() {
            if (hasEditAccess) {
                unlockUI();
            } else {
                lockUI();
            }
        }

        function lockUI() {
            $('#btn_Save, #btn_Update').hide();
            $(document).find('.btn-edit').hide();
        }

        function unlockUI() {
            $('#btn_Save, #btn_Update').show();
            $(document).find('.btn-edit').show();
        }

        function loadFormulaForPlant() {
            debugger;
            let plantId = $("#ddl_PlantName").val();
            let billTypeId = $("#ddl_Ptype").val();
            let monthYear = $("#txtmonth").val();

            if (!plantId || !billTypeId) {
                alert("Please select Generator Name and Plant Name first!");
                return;
            }

            if (!monthYear) {
                alert("Please select Month-Year!");
                return;
            }


            $.ajax({
                type: "POST",
                url: "ECR_INPUT.aspx/GetFormulaForPlant",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                data: JSON.stringify({
                    plantId: plantId,
                    billTypeId: billTypeId
                }),
                success: function (response) {
                    let result = JSON.parse(response.d);

                    if (result.success) {
                        currentFormula = result.formula;
                        formulaTerms = result.terms;
                        $("#tableContainer").show();
                        $("#Id_Section2").show();

                        displayFormulaSection();
                    }

                    else {
                        alert(result.message || "No formula found for selected plant!");
                        $("#formulaContainer").remove();
                    }
                },
                error: function (xhr) {
                    alert("Error loading formula: " + xhr.responseText);
                    $("#formulaContainer").remove();
                }
            });
        }

        /* function displayFormulaSection() {
 
             let terms = extractTermsFromFormula(currentFormula);
 
             $("#formulaDisplay")
                 .html(`<strong>Formula:</strong> ${currentFormula}`)
                 .show();
 
             let headerHtml = `
 <tr class="table-primary">
     <th width="5%">#</th>
     <th width="20%">Term Code</th>
     <th width="45%">Term Name</th>
     <th width="30%">Value</th>
 </tr>`;
             $("#dataTableHeader").html(headerHtml);
 
             let bodyHtml = "";
 
             terms.forEach((term, index) => {
 
                 let termInfo = formulaTerms[term];
 
                 bodyHtml += `
 <tr>
     <td class="text-center">${index + 1}</td>
     <td><strong class="text-primary">${term}</strong></td>
     <td>${termInfo.DisplayName}</td>
     <td>
         <input type="number"
                class="form-control term-input"
                data-term="${term}"
                data-tid="${termInfo.TID}"
                value="${termInfo.CurrentValue || ''}"
                step="0.01"
                placeholder="Enter value">
     </td>
 </tr>`;
             });
 
             $("#dataTableBody").html(bodyHtml);
             let footerHtml = `
 <tr id="resultRow" style="display:none;">
     <td colspan="4" class="text-center fw-bold fs-5 text-success">
         ECR = <span id="finalResult"></span>
     </td>
 </tr>`;
             $("#dataTableFooter").html(footerHtml);
 
             $(".term-input").on("input", function () {
                 autoCalculateFormula();
             });
         }*/


        let formulaTable = null;
        let resultRowIndex = null;

        function displayFormulaSection() {

            let terms = extractTermsFromFormula(currentFormula);

            $("#formulaDisplay")
                .html(`<strong>Formula:</strong> ${currentFormula}`)
                .show();

            $('#tableContainer').show();

            const tableElement = $('#energyTable');

            if ($.fn.DataTable.isDataTable(tableElement)) {
                tableElement.DataTable().destroy();
                tableElement.empty();
            }

            const tableData = terms.map((term, index) => {
                const termInfo = formulaTerms[term];
                return {
                    sno: index + 1,
                    code: term,
                    name: termInfo.DisplayName,
                    value: `
                <input type="number"
                       class="form-control term-input"
                       data-term="${term}"
                       value="${termInfo.CurrentValue || ''}"
                       data-tid="${termInfo.TID}"
                       step="0.01">
            `,
                    isResultRow: false
                };
            });

            tableData.push({
                sno: '',
                code: '',
                name: '',
                value: '',
                isResultRow: true
            });

            formulaTable = tableElement.DataTable({
                data: tableData,
                height: '400px',
                scrollX: true,
                scrollY: '400px',
                scrollCollapse: true,
                responsive: true,
                autoWidth: false,
                fixedHeader: true,
                destroy: true,
                paging: false,
                info: true,
                searching: true,
                ordering: false,
                order: [],
                dom: 'rt',
                columns: [
                    { title: "SlNo", data: "sno", width: "5%", className: "text-center" },
                    { title: "Term Code", data: "code", width: "20%" },
                    { title: "Term Name", data: "name", width: "45%" },
                    { title: "Value", data: "value", width: "30%" }
                ],
                createdRow: function (row, data, dataIndex) {
                    if (data.isResultRow) {
                        $(row).addClass('table-success fw-bold');
                        $(row).hide();
                        resultRowIndex = dataIndex;
                    }
                },
                drawCallback: function () {
                    bindFormulaInputs();
                }
            });

            $('#searchInput').off('keyup input').on('keyup input', function () {
                formulaTable.search(this.value).draw();
            });
        }



        function extractTermsFromFormula(formula) {
            let terms = formula.match(/[A-Z_][A-Z0-9_]*/gi) || [];

            terms = terms.filter(term => isNaN(term));

            return [...new Set(terms)];
        }

        function bindFormulaInputs() {
            $('.term-input').off('input').on('input', function () {
                calculateFormula();
            });
        }

        function calculateFormula() {

            try {
                let formulaToEval = currentFormula;
                let missing = [];

                $(".term-input").each(function () {
                    let term = $(this).data("term");
                    let value = $(this).val();

                    if (value === "") {
                        missing.push(term);
                    } else {
                        let regex = new RegExp(`\\b${term}\\b`, "gi");
                        formulaToEval = formulaToEval.replace(regex, value);
                    }
                });

                if (missing.length > 0) {
                    return;
                }

                let result = eval(formulaToEval).toFixed(4);

                const resultText = `ECR = ${result}`;

                formulaTable.cell(resultRowIndex, 1).data('');
                formulaTable.cell(resultRowIndex, 2).data(
                    `<span class="fs-5 text-success">ECR</span>`
                );
                formulaTable.cell(resultRowIndex, 3).data(
                    `<span class="fs-5 text-success">${result}</span>`
                );

                $(formulaTable.row(resultRowIndex).node()).show();
                formulaTable.draw(false);

            } catch (err) {
                showWarningmessage("Calculation error");
            }
        }


        /*function calculateFormula() {

            try {
                let formulaToEval = currentFormula;
                let missing = [];

                $(".term-input").each(function () {
                    let term = $(this).data("term");
                    let value = $(this).val();

                    if (value === "") {
                        missing.push(term);
                    } else {
                        let regex = new RegExp(`\\b${term}\\b`, "gi");
                        formulaToEval = formulaToEval.replace(regex, value);
                    }
                });

                if (missing.length > 0) {
                    alert("Please enter values for: " + missing.join(", "));
                    return;
                }

                let result = eval(formulaToEval);

                $("#finalResult").text(result.toFixed(4));
                $("#resultRow").show();

            } catch (err) {
                alert("Calculation error: " + err.message);
            }
        }*/

        /* function clearFormulaSection() {
             $("#dataTableHeader").empty();
             $("#dataTableBody").empty();
             $("#dataTableFooter").empty();
             currentFormula = "";
             formulaTerms = {};
         }*/



        function clearFormulaSection() {
            if ($.fn.DataTable.isDataTable('#energyTable')) {
                $('#energyTable').DataTable().clear().destroy();
                $('#energyTable').empty();
            }

            $("#formulaDisplay").hide();
            $("#resultRow").hide();
            currentFormula = "";
            formulaTerms = {};
        }


        function saveECRData() {
            debugger;
            let plantId = $("#ddl_PlantName").val();
            let billTypeId = $("#ddl_Ptype").val();
            let monthYear = $("#txtmonth").val();

            if (!plantId || !billTypeId || !monthYear) {
                showWarningmessage("Select Required Fields");
                return;
            }

            if (!currentFormula) {
                showWarningmessage("No formula loaded!");
                return;
            }

            let termValues = {};
            $(".term-input").each(function () {
                let term = $(this).data("term");
                let tid = $(this).data("tid");
                let value = $(this).val();

                termValues[term] = {
                    termId: tid,
                    value: (value === "" || isNaN(value)) ? "0" : value
                };
            });

            let resultCellHtml = formulaTable
                .cell(resultRowIndex, 3)
                .data();

            let calculatedValue = $('<div>').html(resultCellHtml).text().trim();

            if (!calculatedValue) {
                showWarningmessage("ECR not calculated!");
                return;
            }

            $.ajax({
                type: "POST",
                url: "ECR_INPUT.aspx/SaveECRData",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                data: JSON.stringify({
                    plantId: plantId,
                    billTypeId: billTypeId,
                    monthYear: monthYear,
                    formula: currentFormula,
                    termValues: termValues,
                    calculatedValue: calculatedValue
                }),
                success: function (response) {
                    let result = JSON.parse(response.d);

                    if (result.success) {
                        showSuccessMessage("Data Saved Successfully!");


                        $("#formulaDisplay").show();
                        $("#txtmonth").val("");
                        $("#ddl_PlantName").val("");
                        $("#ddl_Ptype").val("");
                        $("#Id_Section2").show();
                        // clearValueColumn();
                        $("#txtmonth, #ddl_Ptype, #ddl_PlantName").show();
                    } else {
                        showInfoMessage("Data Exist For The Month: " + monthYear);
                        $("#Id_Section2").hide();
                        $("#Id_Section1").show();
                        $("#btn_viewbtn").show();
                        $("#btn_Add").show();
                        $("#btn_back").hide();
                        $("#formulaDisplay").hide();
                        clearFormulaSection();
                        loadExistingECRData();
                        $("#btn_Add").hide(); $("#btn_back").show();
                        $("#ddl_PlantName").off("change");


                    }
                },
                error: function (xhr) {
                    alert("Error saving data: " + xhr.responseText);
                }
            });
        }

        function clearValueColumn() {

            $('.term-input').val('');

            if (formulaTable && resultRowIndex !== null) {

                formulaTable.cell(resultRowIndex, 1).data('');
                formulaTable.cell(resultRowIndex, 2).data('');
                formulaTable.cell(resultRowIndex, 3).data('');

                $(formulaTable.row(resultRowIndex).node()).hide();
                formulaTable.draw(false);
            }
        }


        function Get_PlantName() {
            let GenType = 1;
            let Plant_CompType = $("#ddl_Ptype").val();

            if (!Plant_CompType) {
                alert("Please Select Required Fields");
                return;
            }

            $.ajax({
                type: "POST",
                url: "ECR_INPUT.aspx/Get_Plants",
                contentType: "application/json; charset=utf-8",
                data: JSON.stringify({ GenType, Plant_CompType }),
                dataType: "json",
                success: function (response) {
                    let ddl = $("#ddl_PlantName");
                    ddl.empty();

                    ddl.append('<option value="">Select Plant Name</option>');


                    $.each(response.d, function (i, item) {
                        ddl.append(`<option value="${item.PID}">${item.PLANTNAME}</option>`);
                    });
                }
            });
        }

        function Get_Plant_Company() {
            let GenType = 1;

            $.ajax({
                type: "POST",
                url: "ECR_INPUT.aspx/Get_Plant_CompType",
                contentType: "application/json; charset=utf-8",
                data: JSON.stringify({ GenType }),
                dataType: "json",
                success: function (response) {
                    let ddl = $("#ddl_Ptype");
                    ddl.empty();

                    if (response.d.length > 1) {
                        ddl.append('<option value="">-- Select Generator Name --</option>');
                    }

                    $.each(response.d, function (i, item) {
                        ddl.append(`<option value="${item.CPID}">${item.CPLANTNAME}</option>`);
                    });
                }
            });
        }


        function autoCalculateFormula() {

            let formulaToEval = currentFormula;

            $(".term-input").each(function () {
                let term = $(this).data("term");
                let value = $(this).val();

                if (value === "" || isNaN(value)) {
                    value = 0;
                }

                let regex = new RegExp(`\\b${term}\\b`, "gi");
                formulaToEval = formulaToEval.replace(regex, value);
            });

            $("#resultRow").show();

            try {
                let result = eval(formulaToEval);

                if (isNaN(result) || !isFinite(result)) {
                    $("#finalResult").text("0.0000");
                    return;
                }

                $("#finalResult").text(result.toFixed(4));

            } catch (err) {
                console.error("Auto calculation error:", err);
                $("#finalResult").text("0.0000");
            }
        }



        function loadExistingECRData() {
            debugger;

            let plantId = $("#ddl_PlantName").val();
            let billTypeId = $("#ddl_Ptype").val();
            let monthYear = $("#txtmonth").val();

            if (!plantId || !billTypeId || !monthYear) {
                alert("Please select Month, Generator and Plant Name!");
                return;
            }


            $.ajax({
                type: "POST",
                url: "ECR_INPUT.aspx/GetECRData",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                data: JSON.stringify({
                    plantId: plantId,
                    billTypeId: billTypeId,
                    monthYear: monthYear
                }),
                success: function (response) {
                    debugger;

                    let result = JSON.parse(response.d);
                    console.log(result);

                    if (result.success && Array.isArray(result.data) && result.data.length > 0) {
                        $("#formulaDisplay").hide();
                        $("#tableContainer").hide();
                        $("#txt_Handson_Table").show();
                        $("#logview").show();
                        result.data.forEach((row, index) => {
                            row.slno = index + 1;
                            row.generator_name = $("#ddl_Ptype option:selected").text();
                            row.plant_name = $("#ddl_PlantName option:selected").text();
                        });

                        displayECRHandsontable(result.data);
                        /* $("#Id_Section3").show();*/

                    } else {
                        $("#formulaDisplay").hide();
                        $("#tableContainer").hide();
                        $("#txt_Handson_Table").hide();
                        $("#logview").hide();
                        showWarningmessage("No Data Found");
                        /* $("#Id_Section3").hide();*/
                    }
                },
                error: function (xhr) {
                    console.error(xhr);
                    $("#ecrTableContainer").html(`
                <div class="alert alert-danger">
                    Error loading data
                </div>
            `);
                    /*$("#Id_Section3").hide();*/
                }
            });
        }


        function displayECRHandsontable(data) {

            const container = document.getElementById('ecrTableContainer');

            if (hot) {
                hot.destroy();
            }

            hot = new Handsontable(container, {
                data: data,
                stretchH: 'all',
                height: Math.min(450, data.length * 40 + 60),
                licenseKey: 'non-commercial-and-evaluation',
                rowHeaders: false,
                manualColumnResize: true,


                hiddenColumns: {
                    columns: [1, 5],
                    indicators: false
                },

                colWidths: [
                    60,   // Sl No
                    0,   // ECR ID
                    90,  // Month-Year
                    240,  // Generator
                    140,  // Plant Name
                    0,   // Term Id
                    100,  // Term Name
                    100,  // ECR Value
                    100,  // Added_by
                    100,  // AddedOn
                    160   // Action
                ],
                colHeaders: [
                    'Sl No',
                    'ECR ID',
                    'Month-Year',
                    'Generator',
                    'Plant Name',
                    'Term Id',
                    'Term Name',
                    'ECR Value',
                    'Added_by',
                    'AddedOn',
                    'Action'
                ],

                columns: [
                    { data: 'slno', readOnly: true },
                    { data: 'ecr_id', readOnly: true },
                    {
                        data: 'month_year',
                        readOnly: true,
                        /*renderer: (i, td, r, c, p, v) => {
                            td.textContent = v ? new Date(v).toLocaleDateString('en-GB') : '';
                        }*/
                    },
                    { data: 'generator_name', readOnly: true },

                    { data: 'plant_name', readOnly: true },
                    { data: 'term_id', readOnly: true },
                    { data: 'term_head', readOnly: true },
                    { data: 'term_value' },
                    {
                        data: 'added_by',
                        readOnly: true,

                    },
                    {
                        data: 'created_date',
                        readOnly: true,
                        renderer: (i, td, r, c, p, v) => {
                            td.textContent = v ? new Date(v).toLocaleDateString('en-GB') : '';
                        }
                    },
                    {
                        data: null,
                        readOnly: true,
                        renderer: function (instance, td, row) {
                            Handsontable.dom.empty(td);

                            if (editingRowIndex === row) {
                                td.style.textAlign = "center";
                                const updateBtn = document.createElement('button');
                                updateBtn.type = "button";
                                updateBtn.textContent = 'Update';
                                updateBtn.className = 'btn btn-success m-1';

                                updateBtn.onmousedown = function (e) {
                                    e.preventDefault();
                                    e.stopImmediatePropagation();
                                };

                                updateBtn.onclick = function (e) {
                                    e.preventDefault();
                                    e.stopPropagation();

                                    const editor = hot.getActiveEditor();
                                    if (editor && editor.isOpened()) {
                                        editor.finishEditing();
                                    }

                                    updateECRRow(row);
                                };

                                const cancelBtn = document.createElement('button');
                                cancelBtn.type = "button";
                                cancelBtn.textContent = 'Cancel';
                                cancelBtn.className = 'btn btn-secondary m-1';

                                cancelBtn.onmousedown = function (e) {
                                    e.preventDefault();
                                    e.stopImmediatePropagation();
                                };

                                cancelBtn.onclick = function (e) {
                                    e.preventDefault();
                                    e.stopPropagation();
                                    handleRowAction('cancel', row);
                                };

                                td.appendChild(updateBtn);
                                td.appendChild(cancelBtn);

                            } else {
                                td.style.textAlign = "center";
                                const editBtn = document.createElement('button');
                                editBtn.type = "button";
                                editBtn.textContent = 'Edit';
                                editBtn.className = 'btn btn-primary m-1';

                                editBtn.onmousedown = function (e) {
                                    e.preventDefault();
                                    e.stopImmediatePropagation();
                                };

                                editBtn.onclick = function (e) {
                                    e.preventDefault();
                                    e.stopPropagation();
                                    handleRowAction('edit', row);
                                };

                                td.appendChild(editBtn);
                            }
                        }
                    }
                ],

                cells: function (row, col) {
                    const cellProperties = {};

                    if (col === 7) {
                        cellProperties.type = 'numeric';
                        cellProperties.numericFormat = { pattern: '0.0000' };

                        cellProperties.readOnly = editingRowIndex !== row;

                        cellProperties.allowInvalid = false;

                        cellProperties.validator = function (value, callback) {

                            if (value === null || value === '') {
                                callback(false);
                                return;
                            }

                            const isValid = !isNaN(value) && isFinite(value);
                            callback(isValid);
                        };

                        cellProperties.editor = 'numeric';
                    }

                    return cellProperties;
                }



            });

        }

        function handleRowAction(action, rowIndex) {

            const ECR_COL = 7;

            if (action === 'edit') {

                editingRowIndex = rowIndex;

                originalRowData = JSON.parse(
                    JSON.stringify(hot.getSourceDataAtRow(rowIndex))
                );

                hot.render();

                hot.selectCell(rowIndex, ECR_COL);

                setTimeout(() => {
                    const editor = hot.getActiveEditor();
                    if (editor) editor.beginEditing();
                }, 50);

                return;
            }

            if (action === 'cancel') {

                const ECR_COL = 7;

                const editor = hot.getActiveEditor();

                if (editor && editor.isOpened()) {
                    editor.cancelChanges();
                    editor.close();
                }

                hot.setDataAtRowProp(
                    rowIndex,
                    'term_value',
                    originalRowData.term_value,
                    'cancel'
                );

                editingRowIndex = null;
                originalRowData = null;

                hot.deselectCell();
                hot.render();
            }

        }


        function updateECRRow(rowIndex) {

            const ECR_COL = 7;

            const editor = hot.getActiveEditor();

            if (editor && editor.isOpened()) {
                editor.finishEditing();
            }

            setTimeout(() => {

                const rowData = hot.getSourceDataAtRow(rowIndex);
                const newValue = rowData.term_value;

                console.log("NEW VALUE:", newValue);

                $.ajax({
                    type: "POST",
                    url: "ECR_INPUT.aspx/UpdateECRData",
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    data: JSON.stringify({
                        ecrId: rowData.ecr_id,
                        termId: rowData.term_id,
                        TermValue: newValue,
                        Month: rowData.month_year
                    }),
                    success: function (res) {

                        const result = JSON.parse(res.d);

                        if (result.success) {

                            editingRowIndex = null;
                            originalRowData = null;

                            hot.deselectCell();
                            hot.render();

                            showSuccessMessage("Data Updated Successfully");
                        }
                    }
                });

            }, 100);
        }


        function performUpdate(rowIndex) {
            setTimeout(() => {
                const ECR_COL_INDEX = 7;

                const rowData = hot.getSourceDataAtRow(rowIndex);

                const updatedValue = rowData.term_value;

                console.log("Sending NEW value to server:", updatedValue);

                $.ajax({
                    type: "POST",
                    url: "ECR_INPUT.aspx/UpdateECRData",
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    data: JSON.stringify({
                        ecrId: rowData.ecr_id,
                        termId: rowData.term_id,
                        TermValue: updatedValue,
                        Month: rowData.month_year
                    }),
                    success: function (response) {
                        let result = JSON.parse(response.d);

                        if (result.success) {
                            editingRowIndex = null;
                            originalRowData = null;
                            hot.deselectCell();
                            hot.render();
                            showSuccessMessage("Data Updated Successfully");
                            loadExistingECRData();
                        }
                    }
                });
            }, 50);
        }




        function showLogViewModal() {
            debugger;

            let plantId = $("#ddl_PlantName").val();
            let billTypeId = $("#ddl_Ptype").val();
            let monthYear = $("#txtmonth").val();

            if (!plantId || !billTypeId || !monthYear) {
                alert("Please select Month, Generator and Plant Name");
                return;
            }

            /* $("#modalLogBody").html(`
         <div class="text-center">
             <i class="fa fa-spinner fa-spin fa-3x"></i>
             <p>Loading...</p>
         </div>
     `);*/

            /*$('#staticBackdrop').modal('show');*/

            $.ajax({
                type: "POST",
                url: "ECR_INPUT.aspx/GetLogData",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                data: JSON.stringify({
                    monthYear: monthYear,
                    plantId: plantId,
                    billTypeId: billTypeId
                }),

                success: function (response) {

                    let data = JSON.parse(response.d);

                    if (!data || data.length === 0) {
                        showWarningmessage("No Data Found");
                        $('#staticBackdrop').modal('hide');
                        return;
                    }

                    $('#staticBackdrop').modal('show');
                    let tableHtml = `
                <div style="overflow:auto; max-height:400px;">
                    <table class="table table-bordered table-sm">
                        <thead class="table-active text-center">
                            <tr>
                                <th>Sl.No</th>
                                <th>Month</th>
                                <th>Term</th>
                                <th>Term Value</th>
                                <th>Updated By</th>
                                <th>Updated On</th>
                            </tr>
                        </thead>
                        <tbody>
            `;

                    $.each(data, function (index, item) {

                        let updatedOn = item.UPDATEDON
                            ? new Date(
                                parseInt(item.UPDATEDON.replace(/\/Date\((\d+)\)\//, "$1"))
                            ).toLocaleString("en-GB")
                            : "";

                        tableHtml += `
                    <tr>
    <td class="text-center">${index + 1}</td>
    <td class="text-center">
       ${new Date(parseInt(item.MONTH_YEAR.replace(/\/Date\((\d+)\)\//, '$1'))).toLocaleString('en-GB', { month: 'short', year: 'numeric' })}

    </td>
    <td class="text-center">${item.TERM_HEAD || ''}</td>
    <td class="text-center">${item.TERM_VALUE ?? ''}</td>
    <td class="text-center">${item.UPDATEDBY || ''}</td>
    <td class="text-center">${updatedOn}</td>
</tr>

                `;
                    });

                    tableHtml += `
                        </tbody>
                    </table>
                </div>
            `;

                    $("#modalLogBody").html(tableHtml);
                },

                error: function () {
                    $("#modalLogBody").html(
                        '<div class="alert alert-danger">Error loading log data</div>'
                    );
                }
            });
        }


    </script>

</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="Server">
    <div class="container-fluid">

        <div class="card mt-2">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h6 class="mb-0">ECR Input</h6>

                <button type="button" id="btn_Add" class="btn btn-primary">
                    Add
                </button>
                <button type="button" id="btn_back" class="btn btn-danger">
                    Back
                </button>

            </div>
            <div class="card-body mb-0 pb-0" id="Id_Section1">
                <div class="row">
                    <div class="col-md-3 mb-3">
                        <label class="form-label">Month-Year<span class="text-danger">*</span> :</label>
                        <div class="input-group">
                            <input type="text" id="txtmonth" onkeydown="false" class="form-control datepicker-pick-level_Month_Default_PastMonth"
                                placeholder="MM-YYYY" />
                        </div>
                    </div>


                    <div class="col-md-3 mb-3">
                        <label class="form-label">Generator Name<span class="text-danger">*</span> :</label>
                        <select id="ddl_Ptype" class="form-select">
                            <option value="">Select Generator Name</option>
                        </select>
                    </div>

                    <div class="col-md-3 mb-3">
                        <label class="form-label">Plant Name :<span class="text-danger">*</span></label>
                        <select id="ddl_PlantName" class="form-select">
                            <option value="">Select Plant Name</option>
                        </select>
                    </div>
                </div>

                <div class="col-md-12 text-end mb-3">
                    <button type="button" id="btn_viewbtn" class="btn btn-primary">
                        View
                    </button>
                    <button type="button" class="btn btn-primary ms-2" id="logview">Log View</button>


                </div>

                <div class="" id="txt_Handson_Table">
                    <div id="ecrTableContainer" class="mb-3"></div>
                </div>

                <div class="modal fade" id="staticBackdrop" role="dialog" data-bs-keyboard="false" tabindex="-1" aria-labelledby="staticBackdropLabel" aria-hidden="true">
                    <div class="modal-dialog modal-xl">
                        <div class="modal-content">
                            <div class="modal-header">
                                <h5 class="modal-title" id="staticBackdropLabel">Log View</h5>
                                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                            </div>

                            <div class="modal-body" id="modalLogBody">
                                <div class="alert alert-success" role="alert" id="ALERMSG" runat="server" visible="false">No Data Found</div>
                                <div style="overflow: auto; height: 400px;">
                                </div>
                            </div>


                            <div class="modal-footer">
                                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                            </div>
                        </div>
                    </div>
                </div>

            </div>




            <div class="card-body mt-0 pt-0" id="Id_Section2" style="display: none;">

                <div id="formulaDisplay"
                    class="alert alert-info fw-bold"
                    style="display: none;">
                </div>

                <%--<div class="row" id="dataContainer">
                    <div class="col-12 mb-3">
                        <div class="table-responsive table-container">
                            <table id="readingTable" class="table table-striped table-bordered">
                                <thead id="dataTableHeader"></thead>
                                <tbody id="dataTableBody"></tbody>
                                <tfoot id="dataTableFooter"></tfoot>
                            </table>
                        </div>
                    </div>
                </div>--%>

                <div id="tableContainer" class="" style="display: none;">
                    <div id="energyTable_wrapper" class="dataTables_wrapper dt-bootstrap5 no-footer">
                        <div class="d-flex">
                            <div id="energyTable_filter" class="dataTables_filter TableClassFilter">
                                <label>
                                    <span class="me-3">Filter:</span>
                                    <div class="form-control-feedback form-control-feedback-end flex-fill">
                                        <input type="search" id="searchInput" class="form-control" placeholder="Type to filter..." aria-controls="energyTable">
                                        <div class="form-control-feedback-icon"><i class="ph-magnifying-glass opacity-50"></i></div>
                                    </div>
                                </label>
                            </div>
                        </div>

                        <table id="energyTable" class="table table-striped table-bordered mb-3">
                        </table>

                        <%--<div id="resultRow"
                            class="text-center fw-bold fs-5 text-success mt-3"
                            style="display: none;">
                            ECR = <span id="finalResult"></span>
                        </div>--%>
                    </div>
                </div>



                <div class="row">
                    <div class="col-12">
                        <div class="d-flex flex-wrap justify-content-end">

                            <button type="button" id="btn_Save" class="btn btn-success">
                                Save
                            </button>

                            <button type="button" id="btn_Cancel" class="btn btn-primary d-none">
                                Cancel
                            </button>

                            <button type="button" id="btn_Update" class="btn btn-success d-none">
                                Update
                            </button>

                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</asp:Content>
