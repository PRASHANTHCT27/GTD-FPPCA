<%@ Page Title="" Language="C#" MasterPageFile="~/GTDMaster.master" AutoEventWireup="true" CodeFile="Frm_Formula_Maker.aspx.cs" Inherits="CGS_Frm_Formula_Maker" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">


    <script>
        var currentFormula = "";

        var editFID = null;
        var isEditMode = false;

        var Generation_type = 0;
        var Generator_Name = 0;

        let allowedUsers = [];
        let hasEditAccess = false;
        let loggedUserId = null;

        $(document).ready(function () {
            debugger;
            initUserAccess();

            $('#btn_Add').hide();
            $("#btn_back").hide();

            getUserDetails(function () {

                Get_User();

            });

            function initUserAccess() {
                getUserDetails(function () {
                    getAllowedUsers(function () {
                        checkUserAccess();
                    });
                });
            }

            function getUserDetails(callback) {
                $.ajax({
                    type: 'POST',
                    url: 'Frm_Formula_Maker.aspx/getLoginUserId',
                    contentType: 'application/json; charset=utf-8',
                    dataType: 'json',
                    data: JSON.stringify({}),
                    success: function (res) {
                        loggedUserId = Number(res.d);
                        if (callback) callback();
                    },
                    error: function (err) {
                        console.error("UserId error:", err.responseText);
                    }
                });
            }

            function getAllowedUsers(callback) {
                $.ajax({
                    type: "POST",
                    url: "Frm_Formula_Maker.aspx/GetAllowedUserIds",
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (res) {
                        allowedUsers = res.d.map(Number);
                        hasEditAccess = allowedUsers.includes(loggedUserId);
                        if (callback) callback();
                    },
                    error: function (xhr) {
                        console.error("Permission error:", xhr.responseText);
                    }
                });
            }

            function checkUserAccess() {
                $('#btn_Save, #btn_Update, .btn-edit').toggle(hasEditAccess);
            }



            function checkUserAccess() {
                if (hasEditAccess) {
                    $('#btn_Save').show();
                    $('.btn-edit').show();
                    $('#btn_Update').show();
                    $('#btn_Add').show();
                } else {
                    $('#btn_Save').hide();
                    $('#btn_Update').hide();
                    $('.btn-edit').hide();
                    $('#btn_Add').hide();
                }
            }

            $("#Id_Section2").hide();
            $("#btn_back").hide();

            $("#txt_rem").hide();



            loadThermalTerms();

            $("#btn_Add").on("click", function () {
                $("#btn_back").show();
                $("#Id_Section2").show();
                $("#Id_Section1").hide();
                $("#btn_Add").hide();
                $("#btn_Cancel").hide();
                $("#btn_Update").hide();
                $("#ddl_Ptype").empty();
                $("#ddl_Plant_type").empty();
                $("#ddl_PlantName").empty();

                Get_Plant_Company();
            });

            $("#btn_back").on("click", function () {
                $("#Id_Section1").show();
                $("#Id_Section2").hide();
                $("#btn_Add").show();
                $("#btn_back").hide();
            });

            $("#ddl_Gen_Type").on("change", function () {

                Get_Plant_Company();
            });


            $("#ddl_Ptype").on("change", function () {

                Get_PlantName();
            });


            /* $("#ddl_GenType").on("change", function () {
                 debugger;
                 loadFormulaData();
             });*/

            $("#btn_Update").on("click", function () {
                debugger;
                updateFormula();
            });



            $("#btn_Cancel").on("click", function () {
                debugger;
                Cancel();
            });



            $("#ddl_GenType").on("change", function () {

                Get_Plant_Company();
            });


            /*$("#ddl_Plant_type").on("change", function () {

                Get_PlantName();
            });*/

            $("#btn_viewbtn").on("click", function () {

                loadFormulaData();
            });


            $("#logview").on('click', function (e) {
                e.preventDefault();
                showLogViewModal();
            });

            $(document).on('keydown', function (e) {

                if ($(e.target).is('input, textarea, select')) return;

                if ($('#formulaDisplay').is(':focus')) return;

                if (e.key === 'Backspace') {
                    e.preventDefault();
                    backspace();
                    return;
                }

                if (e.key === 'Enter') {
                    e.preventDefault();
                    return;
                }

                const allowed = /^[0-9a-zA-Z()+\-*/.]$/;

                if (allowed.test(e.key)) {
                    e.preventDefault();
                    currentFormula += e.key;
                    updateFormulaDisplay();
                }
            });

            $('#formulaDisplay').on('input', function () {
                currentFormula = $(this).text().trim();
            });

            $('#formulaDisplay').on('focus', function () {
                if ($(this).text().trim() === 'Your formula will appear here...') {
                    $(this).text('');
                    currentFormula = '';
                }
            });
        });

        function destroyReadingTable() {
            if ($.fn.DataTable.isDataTable('#readingTable')) {
                $('#readingTable').DataTable().clear().destroy();
            }
            $("#dataTableHeader, #dataTableBody, #dataTableFooter").empty();
        }

        function loadThermalTerms() {
            $.ajax({
                type: "POST",
                url: "Frm_Formula_Maker.aspx/GetThermalTerms",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (response) {
                    var result = JSON.parse(response.d);
                    if (result.success) {
                        displayTermButtons(result.data);
                    } else {
                        alert("Error: " + result.message);
                    }
                },
                error: function (xhr, status, error) {
                    alert("Error loading thermal terms: " + error);
                }
            });
        }

        function displayTermButtons(terms) {
            var html = '';
            $.each(terms, function (index, term) {
                html += '<div class="col-md-3 col-sm-4 col-6 mb-2">' +
                    '<button type="button" class="btn btn-outline-primary w-100 py-1 px-2 fw-bold" ' +
                    'data-term="' + term.TERM_NAME + '" ' +
                    'data-bs-toggle="tooltip" ' +
                    'data-bs-placement="top" ' +
                    'title="' + term.TERM_DESCRIPTION + '" ' +
                    'onclick="addToFormula(\'' + term.TERM_NAME + '\')">' +
                    term.TERM_NAME +
                    '</button>' +
                    '</div>';
            });

            $('#termButtonsContainer').html(html);

            var tooltipTriggerList = [].slice.call(
                document.querySelectorAll('[data-bs-toggle="tooltip"]')
            );
            var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
                return new bootstrap.Tooltip(tooltipTriggerEl);
            });
        }


        function addToFormula(value) {
            currentFormula += value;
            updateFormulaDisplay();
        }

        function addOperation(operation) {
            if (currentFormula.length > 0) {
                currentFormula += ' ' + operation + ' ';
                updateFormulaDisplay();
            }
        }

        function addParenthesis(type) {
            currentFormula += type;
            updateFormulaDisplay();
        }

        function clearFormula() {
            currentFormula = "";
            updateFormulaDisplay();
        }

        function backspace() {
            currentFormula = currentFormula.slice(0, -1);
            updateFormulaDisplay();
        }

        function updateFormulaDisplay() {
            $('#formulaDisplay').text(currentFormula || 'Your formula will appear here...');
        }

        function saveFormula() {
            debugger;

            if (!currentFormula || currentFormula.length === 0) {
                alert("Please create a formula first!");
                return;
            }

            var genId = $('#ddl_Gen_Type').val();
            if (!genId) {
                alert("Please select Generation Type!");
                return;
            }

            var PlantId = $("#ddl_PlantName").val();
            var plantName = $('#ddl_PlantName option:selected').text() || null;
            var billTypeId = $('#ddl_Ptype').val() || null;
            var billType = $('#ddl_Ptype option:selected').text() || null;

            $.ajax({
                type: "POST",
                url: "Frm_Formula_Maker.aspx/SaveFormula",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                data: JSON.stringify({
                    formulaExpression: currentFormula,
                    genId: genId,
                    schId: PlantId,
                    billTypeId: billTypeId,
                    plantName: plantName,
                    billType: billType
                }),
                success: function (response) {

                    var result = JSON.parse(response.d);

                    if (result.success) {
                        showSuccessMessage(result.message);

                        clearFormula();
                        $("#Id_Section1").hide();
                    } else {
                        showInfoMessage(result.message);
                    }
                },
                error: function (xhr, status, error) {
                    alert("Error saving formula: " + error);
                }
            });
        }


        function updateFormulaDisplay() {
            if ($('#formulaDisplay').text().trim() !== currentFormula) {
                $('#formulaDisplay').text(currentFormula || 'Your formula will appear here...');
            }
        }


        function evaluateFormula() {
            if (currentFormula.length === 0) {
                alert("Please create a formula first!");
                return;
            }
            alert("Formula to be evaluated: " + currentFormula);
        }



        function Get_PlantName() {
            var GenType = $("#ddl_Gen_Type").val() || $("#ddl_Plant_type").val() || null;
            var Plant_CompType = $("#ddl_Ptype").val();

            if (!GenType || GenType == null || !Plant_CompType) {

                showWarningmessage("Please Select Required Fields");

            }

            $.ajax({
                type: "POST",
                url: "Frm_Formula_Maker.aspx/Get_Plants",
                contentType: "application/json; charset=utf-8",
                data: JSON.stringify({ GenType: GenType, Plant_CompType: Plant_CompType }),
                dataType: "json",
                success: function (response) {
                    var data = response.d;
                    var ddl = $("#ddl_PlantName");
                    ddl.empty();
                    if (data.length > 1) {
                        ddl.append($('<option>', { value: 'ALL', text: 'Select Plant Name' }));
                    }


                    $.each(data, function (i, item) {
                        ddl.append($('<option>', { value: item.PID, text: item.PLANTNAME }));
                    });


                },
                error: function (xhr, status, error) {
                    // showWarningmessage("Error loading Plant Name:");
                }
            });
        }


        function Get_Plant_Company() {
            $("#ddl_Ptype").empty();
            $("#ddl_Plant_type").empty();

            var GenType = $("#ddl_Gen_Type").val() || $("#ddl_GenType").val() || null;

            if (!GenType || GenType == null) {

                showWarningmessage("Please Select GenType");
            }

            $.ajax({
                type: "POST",
                url: "Frm_Formula_Maker.aspx/Get_Plant_CompType",
                contentType: "application/json; charset=utf-8",
                data: JSON.stringify({ GenType: GenType }),
                dataType: "json",
                success: function (response) {
                    var data = response.d;
                    var ddl = $("#ddl_Ptype");

                    var ddl1 = $("#ddl_Plant_type");
                    ddl.empty();
                    if (data.length > 1) {
                        ddl.append($('<option>', { value: 'ALL', text: '-- Select Generator Name --' }));
                        ddl1.append($('<option>', { value: 'ALL', text: '-- Select Generator Name --' }));
                    }


                    $.each(data, function (i, item) {
                        ddl.append($('<option>', { value: item.CPID, text: item.CPLANTNAME }));
                        ddl1.append($('<option>', { value: item.CPID, text: item.CPLANTNAME }));
                    });


                },
                error: function (xhr, status, error) {
                    /*showWarningmessage("Error loading Generator Name:");*/
                }
            });
        }


        //        function loadFormulaData() {
        //            debugger;

        //            var gid = $('#ddl_GenType').val();

        //            var CompType = $('#ddl_Plant_type').val();

        //            $("#dataContainer").hide();

        //            if (!gid || !CompType) {
        //                showWarningmessage("Please select Generation Type");
        //                return;
        //            }

        //            $.ajax({
        //                type: "POST",
        //                url: "Frm_Formula_Maker.aspx/Get_FormulaData",
        //                contentType: "application/json; charset=utf-8",
        //                dataType: "json",
        //                data: JSON.stringify({ GID: gid, CompType: CompType }),
        //                success: function (response) {

        //                    let data = response.d;
        //                    let tbody = "";

        //                    if (data && data.length > 0) {
        //                        $("#dataContainer").show();
        //                        data.forEach((row, i) => {
        //                            tbody += `
        //    <tr
        //        data-fid="${row.FID}"
        //        data-gid="${row.GID}"
        //        data-schid="${row.SCH_ID}"
        //        data-billtypeid="${row.BILL_TYPE_ID}"
        //        data-formula="${encodeURIComponent(row.FORMULA)}">

        //        <td>${i + 1}</td>
        //        <td>${row.FORMULA || ''}</td>
        //        <td>${row.PLANTNAME || ''}</td>
        //        <td>${row.BILL_TYPE || ''}</td>
        //        <td>${row.ADDEDBY || ''}</td>
        //        <td>${row.ADDEDON || ''}</td>
        //        <td>
        //            <button type="button"
        //                class="btn btn-sm btn-primary btn-edit">
        //                <i class="fas fa-edit"></i>
        //            </button>
        //        </td>
        //    </tr>`;
        //                        });

        //                    } else {
        //                        /*tbody = `
        //                    <tr>
        //                        <td colspan="6" class="text-center text-muted">
        //                            No formulas found
        //                        </td>
        //                    </tr>`;*/
        //                        $("#dataContainer").hide();
        //                        showInfoMessage("!No Data Found");
        //                    }

        //                    $("#dataTableHeader").html(`
        //<tr>
        //    <th>Sl.No</th>
        //    <th>Formula</th>
        //    <th>Plant</th>
        //    <th>Bill Type</th>
        //    <th>Added By</th>
        //    <th>Added On</th>
        //    <th>Edit</th>
        //</tr>
        //`);


        //                    $("#dataTableBody").html(tbody);
        //                },
        //                error: function (xhr, status, error) {
        //                    console.error("Error loading formula data:", error);
        //                    alert("Error loading formula data");
        //                }
        //            });
        //        }



        function destroyReadingTable() {
            if ($.fn.DataTable.isDataTable('#readingTable')) {
                $('#readingTable').DataTable().clear().destroy();
            }
            $("#readingTable thead, #readingTable tbody").empty();
            $("#dataTableContainer").hide();
        }

        function loadFormulaData() {
            debugger;

            var gid = $('#ddl_GenType').val();
            var CompType = $('#ddl_Plant_type').val();

            $("#dataTableContainer").hide();

            if (!gid || !CompType) {
                showWarningmessage("Please select Generation Type and Generator Name");
                return;
            }

            $.ajax({
                type: "POST",
                url: "Frm_Formula_Maker.aspx/Get_FormulaData",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                data: JSON.stringify({ GID: gid, CompType: CompType }),
                success: function (response) {
                    let data = response.d;
                    let thead = "";
                    let tbody = "";

                    if (data && data.length > 0) {
                        $("#dataTableContainer").show();

                        thead = `
                    <tr>
                        <th>Sl.No</th>
                         <th>Generator Type</th>
                         <th>Plant</th>
                        <th>Formula</th>
                        
                       
                        <th>Added By</th>
                        <th>Added On</th>
                         <th>Remarks</th>
                        <th>Edit</th>
                    </tr>
                `;

                        data.forEach((row, i) => {

                            let editCell = '';

                            if (hasEditAccess) {
                                editCell = `
            <i class="fa fa-edit btn-edit"
               style="color:blue;cursor:pointer;"
               title="Edit"></i>
        `;
                            } else {
                                editCell = `
            <i class="fas fa-lock"
   style="color:#999;font-size:16px;cursor:not-allowed;"
   title="You don't have edit permission"></i>
        `;
                            }

                            tbody += `
        <tr 
            data-fid="${row.FID}"
            data-gid="${row.GID}"
            data-schid="${row.SCH_ID}"
            data-billtypeid="${row.BILL_TYPE_ID}"
            data-formula="${encodeURIComponent(row.FORMULA)}">

            <td>${i + 1}</td>
            <td>${row.BILL_TYPE || ''}</td>
            <td>${row.PLANTNAME || ''}</td>
            <td>${row.FORMULA || ''}</td>
            <td>${row.ADDEDBY || ''}</td>
            <td>${row.ADDEDON || ''}</td>
            <td>${row.REMARKS || ''}</td>

            <td class="text-center">
                ${editCell}
            </td>
        </tr>
    `;
                        });

                        $("#readingTable thead").html(thead);
                        $("#readingTable tbody").html(tbody);

                    } else {
                        $("#dataTableContainer").hide();
                        showWarningmessage("No Data Found");
                    }
                },
                error: function (xhr, status, error) {
                    console.error("Error loading formula data:", error);
                    alert("Error loading formula data");
                }
            });
        }


        function updateFormula() {
            debugger;
            if (!editFID) {
                alert("No formula selected for update!");
                return;
            }

            if (currentFormula.length === 0) {
                alert("Formula cannot be empty!");
                return;
            }

            var genId = $('#ddl_Gen_Type').val();
            var schId = $('#ddl_PlantName').val();
            var billTypeId = $('#ddl_Ptype').val();
            var plantName = $('#ddl_PlantName option:selected').text();
            var billType = $('#ddl_Ptype option:selected').text();
            var Remarks = $('#txt_remarks').val();

            if (!genId || !schId || !billTypeId || !plantName || !billType || !Remarks) {
                showWarningmessage("Please Enter All The Required Fields");
            }

            $.ajax({
                type: "POST",
                url: "Frm_Formula_Maker.aspx/UpdateFormula",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                data: JSON.stringify({
                    FID: editFID,
                    formulaExpression: currentFormula,
                    genId: genId,
                    schId: schId,
                    billTypeId: billTypeId,
                    plantName: plantName,
                    billType: billType, Remarks: Remarks

                }),
                success: function (res) {
                    showSuccessMessage("Formula updated successfully!");

                    // Store the values globally
                    Generation_type = genId;
                    Generator_Name = billTypeId;

                    clearFormula();
                    editFID = null;
                    isEditMode = false;

                    $("#Id_Section2").hide();
                    $("#Id_Section1").show();

                    $("#btn_Add").show();
                    $("#btn_back").hide();
                    $("#btn_Update").hide();
                    $("#btn_Cancel").hide();
                    $("#btn_Save").show();


                    $("#ddl_GenType").val(Generation_type).trigger("change");

                    setTimeout(function () {
                        $("#ddl_Plant_type").val(Generator_Name);

                        setTimeout(function () {
                            loadFormulaData();
                        }, 300);
                    }, 500);
                },
                error: function () {
                    alert("Error updating formula");
                }
            });
        }

        /*  function updateFormula() {
              debugger;
              if (!editFID) {
                  alert("No formula selected for update!");
                  return;
              }
  
              if (currentFormula.length === 0) {
                  alert("Formula cannot be empty!");
                  return;
              }
  
              var genId = $('#ddl_Gen_Type').val();
              var schId = $('#ddl_PlantName').val();
              var billTypeId = $('#ddl_Ptype').val();
              var plantName = $('#ddl_PlantName option:selected').text();
              var billType = $('#ddl_Ptype option:selected').text();
  
              $.ajax({
                  type: "POST",
                  url: "Frm_Formula_Maker.aspx/UpdateFormula",
                  contentType: "application/json; charset=utf-8",
                  dataType: "json",
                  data: JSON.stringify({
                      FID: editFID,
                      formulaExpression: currentFormula,
                      genId: genId,
                      schId: schId,
                      billTypeId: billTypeId,
                      plantName: plantName,
                      billType: billType
                  }),
                  success: function (res) {
  
                      showSuccessMessage("Formula updated successfully!");
  
  
                      Generation_type = genId;
                      Generator_Name = billTypeId;
  
                      $("#ddl_GenType").val(Generation_type);
                      $("#ddl_Plant_type").val(Generator_Name);
                      
                      
  
                      $("#Id_Section2").hide();
                      $("#Id_Section1").show();
                      clearFormula();
                      editFID = null;
                      isEditMode = false;
  
                      $("#btnUpdateFormula").hide();
                      $("#btnSaveFormula").show();
  
                      loadFormulaData();
                  },
                  error: function () {
                      alert("Error updating formula");
                  }
              });
          }*/



        $(document).on("click", ".btn-edit", function () {

            if (!hasEditAccess) {
                return;
            }

            $("#Id_Section2").show();
            $("#Id_Section1").hide();
            $("#btn_Save").hide();

            $("#txt_rem").show();

            $("#btn_Cancel").show();
            $("#btn_Update").show();

            var row = $(this).closest("tr");

            editFID = row.data("fid");
            isEditMode = true;

            currentFormula = decodeURIComponent(row.data("formula"));
            updateFormulaDisplay();

            $("#ddl_Gen_Type").val(row.data("gid")).trigger("change");

            setTimeout(function () {
                $("#ddl_Ptype").val(row.data("billtypeid")).trigger("change");

                setTimeout(function () {
                    $("#ddl_PlantName").val(row.data("schid"));
                }, 400);
            }, 400);

            $("#btnSaveFormula").hide();
            $("#btnUpdateFormula").show();
        });


        function Cancel() {
            clearFormula();

            $("#btn_back").show();
            $("#btn_Add").hide();
            $("#Id_Section1").hide();
            editFID = null;
            isEditMode = false;

            $("#ddl_Gen_Type").val("");
            $("#ddl_Ptype").empty().append($('<option>', { value: '', text: '-- Select Plant Company Type --' }));
            $("#ddl_PlantName").empty().append($('<option>', { value: '', text: '-- Select Plant Name --' }));

            $("#btn_Save").show();
            $("#btn_Update").hide();
            $("#btn_Cancel").hide();

            /*$("#Id_Section1").show();
            $("#Id_Section2").hide();*/
        }



        function showLogViewModal() {

            var genId = $('#ddl_Gen_Type').val();
            var PlantId = $("#ddl_PlantName").val();
            var billTypeId = $('#ddl_Ptype').val();

            $("#modalLogBody").html(
                '<div class="text-center">' +
                '<i class="fa fa-spinner fa-spin fa-3x"></i>' +
                '<p>Loading...</p></div>'
            );

            $('#staticBackdrop').modal('show');

            $.ajax({
                type: "POST",
                url: "Frm_Formula_Maker.aspx/GetLogData",
                data: JSON.stringify({
                    genId: genId,
                    PlantId: PlantId,
                    billTypeId: billTypeId
                }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",

                success: function (response) {

                    var data = JSON.parse(response.d);

                    if (!data || data.length === 0) {
                        /* $("#modalLogBody").html(
                             '<div class="alert alert-info">No log data found</div>'
                         );*/
                        showWarningMessage("No Data Found");
                        return;
                    }

                    var tableHtml =
                        '<div style="overflow:auto;height:400px;">' +
                        '<table class="table table-bordered table-sm">' +
                        '<thead class="table-active text-center">' +
                        '<tr>' +
                        '<th>Sl.No</th>' +
                        '<th>Formula</th>' +
                        '<th>Plant Name</th>' +
                        '<th>Bill Type</th>' +
                        '<th>Updated By</th>' +
                        '<th>Updated On</th>' +
                        '<th>Remarks</th>' +
                        '</tr>' +
                        '</thead><tbody>';

                    $.each(data, function (index, item) {

                        var updatedOn = item.UPDATEDON
                            ? new Date(
                                parseInt(
                                    item.UPDATEDON.replace(/\/Date\((\d+)\)\//, "$1")
                                )
                            ).toLocaleString("en-GB")
                            : "";

                        tableHtml +=
                            '<tr>' +
                            '<td class="text-center">' + (index + 1) + '</td>' +
                            '<td>' + (item.FORMULA || '') + '</td>' +
                            '<td>' + (item.PLANTNAME || '') + '</td>' +
                            '<td>' + (item.BILL_TYPE || '') + '</td>' +
                            '<td class="text-center">' + (item.UPDATEDBY || '') + '</td>' +
                            '<td class="text-center">' + updatedOn + '</td>' +
                            '<td>' + (item.REMARKS || '') + '</td>' +
                            '</tr>';
                    });

                    tableHtml += '</tbody></table></div>';

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
                <span class="fw-bold">ECR Formula Builder</span>

                    <button type="button" id="btn_Add" class="btn btn-primary btn-sm">
                        Add
                    </button>
                    <button type="button" id="btn_back" class="btn btn-danger btn-sm">
                        Back
                    </button>
            </div>

            <div class="card-body" id="Id_Section1">
                <div class="row">
                    <div class="col-md-3 mb-3">
                        <label class="form-label fw-bold">Generation Type<span class="text-danger">*</span></label>
                        <select id="ddl_GenType" class="form-select">
                            <option value="">-- Select Generation Type --</option>
                            <%--<option value="1">Hydro</option>--%>
                            <option value="1">Thermal</option>
                            <%-- <option value="3">Solar</option>
                            <option value="4">Wind</option>--%>
                        </select>
                    </div>

                    <div class="col-md-3 mb-3">
                        <label class="form-label fw-bold">Generator Name :<span class="text-danger">*</span></label>
                        <select id="ddl_Plant_type" class="form-select">
                            <option value="">-- Select Generator Name --</option>
                        </select>
                    </div>

                    <div class="col-md-12 text-end align-self-end mb-3">
                        <button type="button" id="btn_viewbtn" class="btn btn-primary btn-sm">
                            View
                        </button>

                    </div>
                </div>

                <%-- <div class="row" id="dataContainer">
                    <div class="col-12">
                        <div class="table-responsive table-container">
                            <table id="readingTable" class="table table-striped table-bordered">
                                <thead id="dataTableHeader"></thead>
                                <tbody id="dataTableBody"></tbody>
                                <tfoot id="dataTableFooter"></tfoot>
                            </table>
                        </div>
                    </div>
                </div>--%>

                <div class="row" id="dataTableContainer" style="display: none">
                    <div class="col-12">
                        <div class="table-responsive table-container">
                            <table id="readingTable" class="table table-striped table-bordered" style="width: 100%">
                                <thead></thead>
                                <tbody></tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>



            <div class="card-body" id="Id_Section2">
                <asp:HiddenField runat="server" ID="hidgridrdbtn" Value="null" />

                <div class="row mb-4">
                    <div class="col-md-3 mb-3">
                        <label class="form-label fw-bold">Generation Type :<span class="text-danger">*</span></label>
                        <select id="ddl_Gen_Type" class="form-select">
                            <option value="">Select Generation Type</option>
                            <%-- <option value="1">Hydro</option>--%>
                            <option value="1">Thermal</option>
                            <%-- <option value="3">Solar</option>
                            <option value="4">Wind</option>--%>
                        </select>
                    </div>

                    <div class="col-md-3 mb-3">
                        <label class="form-label fw-bold">Generator Name :<span class="text-danger">*</span></label>
                        <select id="ddl_Ptype" class="form-select">
                            <option value="">-- Select Generator Name --</option>
                        </select>
                    </div>

                    <div class="col-md-3 mb-3">
                        <label class="form-label fw-bold">Plant Name :<span class="text-danger">*</span></label>
                        <select id="ddl_PlantName" class="form-select">
                            <option value="">-- Select Plant Name --</option>
                        </select>
                    </div>

                    <div class="col-md-3 mb-3" id="txt_rem">
                        <label>Remarks<span class="text-danger">*</span> :</label>
                        <input type="text" class="form-control" id="txt_remarks">
                    </div>
                </div>


                <div class="row mb-3 ">
                    <div class="col-12">
                        <label class="form-label fw-bold">Formula Expression :</label>
                        <div id="formulaDisplay"
                            class="alert alert-info border border-2 border-primary p-3 fs-5 fw-semibold text-break"
                            style="min-height: 60px;"
                            contenteditable="true"
                            role="textbox">
                            Your formula will appear here...
                        </div>
                    </div>
                </div>

                <div class="row mb-3">
                    <div class="col-lg-10 col-md-9">
                        <div class="card border-primary mb-3">
                            <div class="card-header bg-light">
                                <h6 class="mb-0 fw-bold text-primary">
                                    <i class="fas fa-cube me-2"></i>Thermal Terms
                                </h6>
                            </div>
                            <div class="card-body">
                                <div class="row" id="termButtonsContainer">
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col-lg-2 col-md-3">
                        <div class="card border-success mb-3">
                            <div class="card-header bg-light py-2 px-2">
                                <h6 class="mb-0 fw-bold text-success small">
                                    <i class="fas fa-plus-circle me-1"></i>Operations
                                </h6>
                            </div>
                            <div class="card-body p-2">
                                <div class="d-grid gap-1">
                                    <button type="button"
                                        class="btn btn-outline-success btn-sm py-1"
                                        onclick="addOperation('+')">
                                        <span class="fs-3 fw-bold lh-1">+</span>
                                    </button>

                                    <button type="button"
                                        class="btn btn-outline-success btn-sm py-1"
                                        onclick="addOperation('-')">
                                        <span class="fs-3 fw-bold lh-1">−</span>
                                    </button>

                                    <button type="button"
                                        class="btn btn-outline-success btn-sm py-1"
                                        onclick="addOperation('*')">
                                        <span class="fs-3 fw-bold lh-1">×</span>
                                    </button>

                                    <button type="button"
                                        class="btn btn-outline-success btn-sm py-1"
                                        onclick="addOperation('/')">
                                        <span class="fs-3 fw-bold lh-1">÷</span>
                                    </button>

                                    <button type="button"
                                        class="btn btn-outline-secondary btn-sm py-1"
                                        onclick="addParenthesis('(')">
                                        <span class="fs-3 fw-bold lh-1">(</span>
                                    </button>

                                    <button type="button"
                                        class="btn btn-outline-secondary btn-sm py-1"
                                        onclick="addParenthesis(')')">
                                        <span class="fs-3 fw-bold lh-1">)</span>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row">
                    <div class="col-12">
                        <div class="d-flex flex-wrap gap-2 justify-content-end">
                            <button type="button" id="btn_Clear" class="btn btn-danger" onclick="clearFormula()">
                                Clear All
                            </button>
                            <%--<button type="button" class="btn btn-warning" onclick="backspace()">
                                <i class="fas fa-backspace me-2"></i>Backspace
                            </button>--%>
                            <button type="button" id="btn_Save" class="btn btn-success" onclick="saveFormula()">
                                Save
                            </button>

                            <button type="button" id="btn_Cancel" class="btn btn-primary">
                                Cancel
                            </button>

                            <button type="button" id="btn_Update" class="btn btn-success">
                                Update
                            </button>
                            <button type="button" class="btn btn-primary btn-sm" <%--style="display: none;" --%>id="logview" data-bs-toggle="modal" data-bs-target="#staticBackdrop">
                                Log View
                            </button>

                        </div>
                    </div>
                </div>


                <div class="modal fade" id="staticBackdrop" role="dialog" data-bs-keyboard="false" tabindex="-1" aria-labelledby="staticBackdropLabel" aria-hidden="true">
                    <div class="modal-dialog modal-xl">
                        <div class="modal-content">
                            <div class="modal-header">
                                <h5 class="modal-title" id="staticBackdropLabel">Log View</h5>
                                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                            </div>

                            <div class="modal-body" id="modalLogBody">
                                <div class="alert alert-success" role="alert" id="ALERMSG" runat="server" visible="false">No Data Found...!</div>
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
        </div>
    </div>
</asp:Content>
