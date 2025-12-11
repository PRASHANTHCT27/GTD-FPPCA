<%@ Page Title="" Language="C#" MasterPageFile="~/GTDMaster.master" AutoEventWireup="true" CodeFile="Process_Config.aspx.cs" Inherits="Process_Config" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <script>
        let globalAllRows = [];
        var allowedUsers = [];

        $(document).ready(function () {
            loadEscoms();
            Get_DATA();
            $("#Id_id1").hide();

            $("#btn_Add").on("click", function () {
                $("#dataTableContainer").hide();
                $("#Id_id1").show();
            });



            function Get_DATA() {
                $("#dataTableContainer").hide();
                $.ajax({
                    url: "Process_Config.aspx/Get_DATA",
                    type: "POST",
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    data: '{}',
                    success: function (res) {
                        var data = res.d;
                        var ddl = $("#ddl_Form_Name");
                        ddl.empty().append('<option value="">-- Select Form --</option>');

                        if (data && data.length > 0) {
                            $("#dataTableContainer").show();
                            $.each(data, function (i, row) {
                                ddl.append(
                                    `<option 
        value="${row.FORMID}" 
        data-formurl="${row.FORMURL}"
        data-moduleid="${row.MODULEID}"
        data-modulename="${row.MODULENAME}">
        ${row.FORMNAMES}
    </option>`
                                );

                            });
                        } else {
                            showInfoMessage("No Data Found");
                        }
                    },
                    error: function (err) {
                        console.log(err);
                        alert("Error fetching data!");
                    }
                });
            }


            $.ajax({
                type: "POST",
                url: "Process_Config.aspx/GetAllowedUserIds",
                data: '{}',
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (res) {
                    allowedUsers = res.d;
                    checkUserAccess();
                },
                error: function (xhr) {
                    console.log("Error: " + xhr.responseText);
                }
            });

            function checkUserAccess() {
                if (allowedUsers.includes(loggedUserId)) {
                    $(".btn-section-save").show();
                } else {
                    $(".btn-section-save").hide();
                }
            }


            function loadEscoms() {
                $.ajax({
                    type: "POST",
                    url: "Process_Config.aspx/GetEscoms",
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (response) {
                        var data = response.d;
                        var ddl = $("#ddlEscoms");
                        ddl.empty().append('<option value="">-- Select ESCOM --</option>');
                        $.each(data, function (i, item) {
                            ddl.append(`<option value="${item.CMID}">${item.CMNAME}</option>`);
                        });
                        loadAssignedDesignations();
                    },
                    error: function (xhr, status, error) {
                        console.error("Error loading ESCOMs:", error);
                    }
                });
            }

            $("#ddlEscoms").on("change", loadAssignedDesignations);

            function loadAssignedDesignations() {
                var escom = $("#ddlEscoms").val();
                $.ajax({
                    type: "POST",
                    url: "Process_Config.aspx/GetAssignedDesignations",
                    data: JSON.stringify({ escom: escom }),
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (response) {
                        var data = response.d;
                        $("#ddl_Des_Name").empty();
                        $.each(data, function (i, item) {
                            $("#ddl_Des_Name").append(
                                `<option value="${item.ID}">${item.Name}</option>`
                            );
                        });
                    },
                    error: function (xhr, status, error) {
                        console.error("Error loading Designations:", error);
                    }
                });
            }



            function LoadProcessDetails() {
                var escomId = $("#ddlEscoms").val();

                $.ajax({
                    url: "Process_Config.aspx/GetProcessDetails",
                    type: "POST",
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",

                    data: JSON.stringify({ ESCOM_ID: escomId }),

                    success: function (res) {

                        var data = JSON.parse(res.d);

                        $("#dataTableBody").empty();
                        $("#dataTableHeader").empty();

                        let header = `
                <tr>
                    <th>SLNO</th>
                    <th>DESG</th>
                    <th>ESCOM</th>
                    <th>FORMNAME</th>
                    <th>FORMURL</th>
                    <th>Read</th>
                    <th>Read & Write</th>
                    <th>SEQUENANCE</th>
                    <th>STATUS</th>
                    <th>EDIT</th>
                </tr>`;
                        $("#dataTableHeader").append(header);

                        data.forEach(function (r, i) {

                            let rowJson = JSON.stringify(r).replace(/"/g, '&quot;'); // safe stringify

                            let row = `
                    <tr>
                        <td>${i + 1}</td>
                        <td>${r.DESG}</td>
                        <td>${r.ESCOM}</td>
                        <td>${r.FORMNAME}</td>
                        <td>${r.FORMURL}</td>
                        <td>${r.PREAD}</td>
                        <td>${r.PWRITE}</td>
                        <td>${r.SEQUENANCE}</td>
                        <td>${r.ACT_INACT == 1 ? "Active" : "Inactive"}</td>

                        <td>
                            <button class="btn btn-sm btn-primary" type="button"
                                onclick="editRow('${rowJson}')">
                                Edit
                            </button>
                        </td>
                    </tr>`;

                            $("#dataTableBody").append(row);
                        });
                    },

                    error: function (xhr) {
                        console.log("Error:", xhr.responseText);
                    }
                });
            }


            const grantedList = $("#grantedList");

            $("#btnGrant").on("click", function () {
                const accessType = $('input[name="accessType"]:checked').val();
                $("#ddl_Des_Name option:selected").each(function () {
                    const designationName = $(this).text();

                    const exists = grantedList.find("li").filter(function () {
                        return $(this).text().split(" / ")[0] === designationName;
                    }).length;

                    if (!exists) {
                        const li = $("<li>").addClass("list-group-item").text(designationName + " / " + accessType);
                        li.on("click", function () { $(this).toggleClass("active"); });
                        grantedList.append(li);
                    }
                });
            });

            $("#btnRevoke").on("click", function () {
                grantedList.find("li.active").remove();
            });


            $("#btn_Add1").on("click", function () {
                debugger;


                var escomId = $("#ddlEscoms").val();
                var escomName = $("#ddlEscoms option:selected").text();


                var formId = $("#ddl_Form_Name").val();
                var formName = $("#ddl_Form_Name option:selected").text();

                var formUrl = $("#ddl_Form_Name option:selected").data("formurl");
                var moduleId = $("#ddl_Form_Name option:selected").data("moduleid");

                if (!escomId || !formId) {
                    alert("Please select ESCOM and Form.");
                    return;
                }


                var readIds = [];
                var readWriteIds = [];
                var sequenceIds = [];

                $("#grantedList li").each(function () {
                    var parts = $(this).text().split(" / ");
                    var designationName = parts[0];
                    var accessType = parts[1];

                    var designationId = $("#ddl_Des_Name option").filter(function () {
                        return $(this).text() === designationName;
                    }).val();

                    if (!designationId) return;

                    sequenceIds.push(designationId);

                    if (accessType === "Read") readIds.push(designationId);
                    if (accessType === "Read/Write") readWriteIds.push(designationId);
                });

                var dataToSend = {
                    ESCOM_ID: escomId,
                    ESCOM_Name: escomName,
                    FormID: formId,
                    FormName: formName,
                    FormURL: formUrl,
                    ModuleID: moduleId,
                    Read_DesignationIDs: readIds.join(","),
                    ReadWrite_DesignationIDs: readWriteIds.join(","),
                    Sequence: sequenceIds.join(",")
                };

                console.log("Data to Save:", dataToSend);


                $.ajax({
                    type: "POST",
                    url: "Process_Config.aspx/SavePermissions",
                    data: JSON.stringify({ permissionsData: dataToSend }),
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (res) {
                        if (res.d == 'Success') {
                            showSuccessMessage("Data Saved SuccessFully");
                        }

                        $("#grantedList").empty();
                    },
                    error: function (xhr, status, error) {
                        console.error("Error saving permissions:", error);
                        alert("Error saving permissions!");
                    }
                });

            });



            const ddlForm = $("#ddl_Form_Name");
            ddlForm.prop('size', 1);

            ddlForm.on('focus', function () {
                const optionCount = ddlForm.find('option').length;
                ddlForm.prop('size', optionCount > 5 ? 5 : optionCount);
            });

            ddlForm.on('blur change', function () {
                ddlForm.prop('size', 1);
            });



            $("#btn_viewbtn").on("click", function () {
                debugger;
                $("#Id_id1").hide();
                $("#dataTableContainer").show();
                LoadProcessDetails();

            });

        });
    </script>



</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-fluid">

        <div class="card mt-0">
            <div class="card-header">
                FPPCA CONFIG
            </div>
            <div class="card-body">

                <div class="row mb-3">

                    <div class="col-md-3">
                        <label class="form-label">Escoms: <span class="text-danger">*</span></label>
                        <select id="ddlEscoms" class="form-select">
                            <option value="">-- Select Escom --</option>
                        </select>
                    </div>
                    <div class="col-md-1 text-center mt-3 mb-2 pt-1">
                        <button type="button" id="btn_viewbtn" class="btn btn-info">View</button>
                    </div>
                    <div class="col-md-1 text-left mt-3 mb-2 pt-1">
                        <button type="button" id="btn_Add" class="btn btn-info">Add</button>
                    </div>
                </div>

                <div class="card mt-3" id="dataTableContainer">
                    <div class="card-body">
                        <div class="table-responsive">
                            <table id="readingTable" class="table table-striped table-bordered text-center w-100">
                                <thead id="dataTableHeader"></thead>
                                <tbody id="dataTableBody"></tbody>
                                <tfoot id="dataTableFooter"></tfoot>
                            </table>
                        </div>
                    </div>
                </div>

            </div>


            <div class="card-body mt-3" id="Id_id1">

                <div class="row mb-3">
                    <%--<div class="col-md-3">
                        <label class="form-label">Escoms: <span class="text-danger">*</span></label>
                        <select id="ddlEscoms" class="form-select">
                            <option value="">-- Select Escom --</option>
                        </select>
                    </div>--%>
                    <div class="col-md-3">
                        <label class="form-label">Form Name: <span class="text-danger">*</span></label>
                        <select id="ddl_Form_Name" class="form-select">
                            <option value="">-- Select Form --</option>
                        </select>
                    </div>


                </div>

                <div class="row mt-3">

                    <div class="col-md-5">
                        <div class="card">
                            <div class="card-header text-center">Designations</div>
                            <div class="card-body text-center p-2 border rounded has-fixed-height">
                                <select id="ddl_Des_Name" class="form-control select " size="10" multiple>
                                    <option value="">-- Select Designations</option>
                                    
                                </select>
                            </div>
                        </div>
                    </div>

                    <div class="col-md-2 d-flex flex-column justify-content-center align-items-center">
                        <div class="card w-100 h-100">
                            <div class="card-header text-center">Access Type & Actions</div>
                            <div class="card-body text-center p-2 border rounded has-fixed-height">

                                <div class="mb-3">
                                    <label class="me-3">
                                        <input type="radio" name="accessType" value="Read" checked>
                                        Read
                                    </label>

                                </div>

                                <div class="mb-3">
                                    <label>
                                        <input type="radio" name="accessType" value="Read/Write">
                                        Read/Write
                                    </label>
                                </div>

                                <%--<div class="d-flex justify-content-center gap-2">--%>
                                <div class="mb-3">
                                    <button id="btnGrant" type="button" class="btn btn-success">&rarr;</button>
                                </div>
                                <div class="mb-3">
                                    <button id="btnRevoke" type="button" class="btn btn-danger">&larr;</button>

                                </div>

                            </div>
                        </div>
                    </div>

                    <div class="col-md-5">
                        <div class="card">
                            <div class="card-header text-center">Granted Permissions</div>
                            <div class="card-body text-center p-2 border rounded has-fixed-height">
                                <ul id="grantedList" class="list-group overflow-auto h-50">
                                </ul>
                            </div>
                        </div>
                    </div>

                </div>

                <div class="row mt-3">
                    <div class="col-md-12 text-end">
                        <button type="button" id="btn_Add1" class="btn btn-info">Save</button>
                    </div>
                </div>

               <%-- <div class="card mt-3" id="dataTableContainer1">
                    <div class="card-body">
                        <div class="table-responsive">
                            <table id="readingTable1" class="table table-striped table-bordered text-center w-100">
                                <thead id="dataTableHeader1"></thead>
                                <tbody id="dataTableBody1"></tbody>
                                <tfoot id="dataTableFooter1"></tfoot>
                            </table>
                        </div>
                    </div>
                </div>--%>

            </div>
        </div>
    </div>


</asp:Content>

