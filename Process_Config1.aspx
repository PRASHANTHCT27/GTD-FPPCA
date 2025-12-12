<%@ Page Title="" Language="C#" MasterPageFile="~/GTDMaster.master" AutoEventWireup="true" CodeFile="Process_Config.aspx.cs" Inherits="Process_Config" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
  <script>
      let globalAllRows = [];
      var allowedUsers = [];

      $(document).ready(function () {
          $("#Id_id1").hide();
          $("#dataTableContainer").hide();

          loadEscoms();
          Get_DATA();

          $("#btn_viewbtn").on("click", function () {
              $("#Id_id1").hide();
              $("#dataTableContainer").show();
              LoadProcessDetails();
          });

          $("#btn_Add").on("click", function () {
              $("#dataTableContainer").hide();
              $("#Id_id1").show();
              $("#ddl_Form_Name").val("");
              $("#ddl_STACK").val("");
              $("#grantedList").empty();
              $("#ddl_Des_Name").empty();

              $("#selectedList").empty();
          });

          $("#btnGrant").on("click", grantSelected);
          $("#btnRevoke").on("click", revokeSelected);
          $("#btn_Add1").on("click", savePermissions);

          /*const ddlForm = $("#ddl_Form_Name");
          ddlForm.prop('size', 1);
          ddlForm.on('focus', function () {
              const optionCount = ddlForm.find('option').length;
              ddlForm.prop('size', optionCount > 5 ? 5 : optionCount);
          });
          ddlForm.on('blur change', function () { ddlForm.prop('size', 1); });*/

          $("#ddlEscoms").on("change", function () {
              Get_StackHolders();
          });

          $("#ddl_STACK").on("change", function () {
              var Stack_id = $("#ddl_STACK").val();

              $("#grantedList").empty();
              $("#ddl_Des_Name").empty();

              if (Stack_id) {
                  loadAssignedDesignations(Stack_id);
              }

              refreshSelectedList();
          });

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
              error: function (xhr) { console.log("Error: " + xhr.responseText); }
          });

          function checkUserAccess() {
              if (allowedUsers.includes(loggedUserId)) {
                  $(".btn-section-save").show();
              } else {
                  $(".btn-section-save").hide();
              }
          }

          function grantSelected() {
              const accessType = $('input[name="accessType"]:checked').val();
              $("#ddl_Des_Name option:selected").each(function () {
                  const designationId = $(this).val();
                  const designationName = $(this).text();

                  if ($("#grantedList li").filter(function () {
                      return $(this).text().split(" / ")[0] === designationName;
                  }).length === 0) {
                      const li = $("<li>")
                          .addClass("list-group-item")
                          .attr("data-id", designationId)
                          .text(designationName + " / " + accessType)
                          .on("click", function () { $(this).toggleClass("active"); });
                      $("#grantedList").append(li);
                      $(this).remove();
                  }
              });
              refreshSelectedList();
          }

          function revokeSelected() {
              $("#grantedList li.active").each(function () {
                  const designationId = $(this).attr("data-id");
                  const designationName = $(this).text().split(" / ")[0];
                  $("#ddl_Des_Name").append(`<option value="${designationId}">${designationName}</option>`);
                  $(this).remove();
              });
              refreshSelectedList();
          }

          function savePermissions() {
              const escomId = $("#ddlEscoms").val();
              const escomName = $("#ddlEscoms option:selected").text();
              const stackholderId = $("#ddl_STACK").val();
              const stackholderName = $("#ddl_STACK option:selected").text();
              const formId = $("#ddl_Form_Name").val();
              const formName = $("#ddl_Form_Name option:selected").text();
              const formUrl = $("#ddl_Form_Name option:selected").data("formurl");
              const moduleId = $("#ddl_Form_Name option:selected").data("moduleid");

              if (!escomId || !formId) {
                  alert("Please select ESCOM and Form.");
                  return;
              }

              if (!stackholderId) {
                  alert("Please select Stakeholder.");
                  return;
              }

              const readIds = [], readWriteIds = [], sequenceIds = [];

              $("#grantedList li").each(function () {
                  const parts = $(this).text().split(" / ");
                  const designationId = $(this).attr("data-id");
                  if (!designationId) return;
                  sequenceIds.push(designationId);
                  if (parts[1] === "Read") readIds.push(designationId);
                  if (parts[1] === "Read/Write") readWriteIds.push(designationId);
              });

              if (sequenceIds.length === 0) {
                  alert("Please grant at least one designation permission.");
                  return;
              }

              const dataToSend = {
                  ESCOM_ID: escomId,
                  ESCOM_Name: escomName,
                  Stakeholder_ID: stackholderId,
                  Stakeholder_Name: stackholderName,
                  FormID: formId,
                  FormName: formName,
                  FormURL: formUrl,
                  ModuleID: moduleId,
                  Read_DesignationIDs: readIds.join(","),
                  ReadWrite_DesignationIDs: readWriteIds.join(","),
                  Sequence: sequenceIds.join(",")
              };

              console.log("Data to send:", dataToSend);

              $.ajax({
                  type: "POST",
                  url: "Process_Config.aspx/SavePermissions",
                  data: JSON.stringify({ permissionsData: dataToSend }),
                  contentType: "application/json; charset=utf-8",
                  dataType: "json",
                  success: function (res) {
                      if (res.d == 'Success') {
                          showSuccessMessage("Data Saved Successfully");
                          // $("#grantedList").empty();
                          // refreshSelectedList();
                      }
                  },
                  error: function (xhr, status, error) {
                      console.error("Error saving permissions:", error);
                      alert("Error saving permissions!");
                  }
              });
          }
      });

      function Get_DATA() {
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
                      $.each(data, function (i, row) {
                          ddl.append(
                              `<option value="${row.FORMID}" 
                           data-formurl="${row.FORMURL || ''}"
                           data-moduleid="${row.MODULEID || ''}"
                           data-modulename="${row.MODULENAME || ''}">
                           ${row.FORMNAMES || row.FORMNAME || ''}
                    </option>`
                          );
                      });
                  }
              },
              error: function (err) {
                  console.log(err);
                  alert("Error fetching data!");
              }
          });
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
              },
              error: function (xhr, status, error) {
                  console.error("Error loading ESCOMs:", error);
              }
          });
      }

      function loadAssignedDesignations(Stack_id) {
          return new Promise(function (resolve, reject) {
              var escom = $("#ddlEscoms").val();
              $.ajax({
                  type: "POST",
                  url: "Process_Config.aspx/GetAssignedDesignations",
                  data: JSON.stringify({ escom: escom, Stack_Id: Stack_id }),
                  contentType: "application/json; charset=utf-8",
                  dataType: "json",
                  success: function (response) {
                      var data = response.d || [];
                      var $ddl = $("#ddl_Des_Name");
                      $ddl.empty();
                      if (data.length > 0) {
                          $.each(data, function (i, item) {
                              $ddl.append(`<option value="${item.ID}">${item.Name}</option>`);
                          });
                      } else {
                          $ddl.append(`<option value="">-- Select Designations --</option>`);
                      }
                      resolve();
                  },
                  error: function (xhr, status, error) {
                      console.error("Error loading Designations:", error);
                      reject(error);
                  }
              });
          });
      }

      function Get_StackHolders() {
          var escom = $("#ddlEscoms").val();

          

          $.ajax({
              url: "Process_Config.aspx/StakeHolders",
              type: "POST",
              contentType: "application/json; charset=utf-8",
              dataType: "json",
              data: JSON.stringify({ ESCOM_ID: escom }),
              success: function (res) {
                  var data = res.d;
                  var ddl = $("#ddl_STACK");
                  ddl.empty();
                  ddl.append('<option value="">-- Select STACKHOLDERS --</option>');
                  if (data && data.length > 0) {
                      $.each(data, function (i, row) {
                          ddl.append(`<option value="${row.ID}">${row.Name}</option>`);
                      });
                  }
              },
              error: function (err) {
                  console.log(err);
                  alert("Error fetching Stackholders!");
              }
          });
      }

      function LoadProcessDetails() {
          var escomId = $("#ddlEscoms").val();

          if (!escomId || escomId === "0" || escomId === null || escomId === "") {
              showWarningmessage("!Select Escoms");
              return;
          }
          $.ajax({
              url: "Process_Config.aspx/GetProcessDetails",
              type: "POST",
              contentType: "application/json; charset=utf-8",
              dataType: "json",
              data: JSON.stringify({ ESCOM_ID: escomId }),
              success: function (res) {
                  var data = JSON.parse(res.d);
                  console.log("Process Details:", data);
                  if (!data || data.length === 0) {
                      $("#dataTableContainer").hide();
                  } else {
                      $("#dataTableContainer").show();
                  }
                  $("#dataTableBody").empty();

                  $("#dataTableHeader").html(`
                <tr>
                    <th>SLNO</th>
                    <th>ESCOM</th>
                    <th style="display:none;">StackHolder ID</th>
                    <th>DESG</th>
                    <th>FORMNAME</th>
                    <th>FORMURL</th>
                    <th style="display:none;">Read</th>
                    <th style="display:none;">Read & Write</th>
                    <th style="display:none;">SEQUENANCE</th>
                    <th>STATUS</th>
                    <th>EDIT</th>
                </tr>`);

                  data.forEach(function (r, i) {
                      let encodedRow = btoa(JSON.stringify(r));

                      let row = `<tr>
                    <td>${i + 1}</td>
                    <td>${r.ESCOM || ''}</td>
                    <td style="display:none;">${r.STACKHOLDER_ID || r.STACKHOLDERID || ''}</td>
                    <td>${r.DESG || ''}</td>
                    <td>${r.FORMNAME || r.FORMNAMES || ''}</td>
                    <td>${r.FORMURL || ''}</td>
                    <td style="display:none;">${r.PREAD || ''}</td>
                    <td style="display:none;">${r.PWRITE || ''}</td>
                    <td style="display:none;">${r.SEQUENANCE || ''}</td>
                    <td>${r.ACT_INACT == 1 ? "Active" : "Inactive"}</td>
                    <td><button class="btn btn-sm btn-primary" type="button"
                        onclick="editRow('${encodedRow}')">Edit</button></td>
                </tr>`;
                      $("#dataTableBody").append(row);
                  });
              },
              error: function (xhr) {
                  console.log("Error:", xhr.responseText);
              }
          });
      }

      function refreshSelectedList() {
          const stackholderName = $("#ddl_STACK option:selected").text();
          const stackholderId = $("#ddl_STACK").val();

          const currentDesignations = [];
          $("#grantedList li").each(function () {
              const designationName = $(this).text().split(" / ")[0];
              currentDesignations.push(`<b>${designationName}</b>`);
          });

          if (stackholderName && stackholderId &&
              stackholderName !== "-- Select STACKHOLDERS --" &&
              currentDesignations.length > 0) {

              const existingRows = $("#selectedList").find(`div[data-stack-id="${stackholderId}"]`);

              if (existingRows.length > 0) {
                  existingRows.html(`${stackholderName} : ${currentDesignations.join(" → ")}`);
              } else {
                  const newRow = `<div data-stack-id="${stackholderId}" style="margin-bottom: 8px;">
                ${stackholderName} : ${currentDesignations.join(" → ")}
            </div>`;
                  $("#selectedList").append(newRow);
              }
          }
      }

      function clearCurrentStackholderSummary() {
          const stackholderId = $("#ddl_STACK").val();
          if (stackholderId) {
              $(`#selectedList div[data-stack-id="${stackholderId}"]`).remove();
          }
      }

      function editRow(encodedRow) {
          console.log("Edit Row Called");
          let r = JSON.parse(atob(encodedRow));
          console.log("Row Data:", r);

          $("#Id_id1").show();
          $("#dataTableContainer").hide();

          $("#selectedList").empty();
          $("#grantedList").empty();
          $("#ddl_Des_Name").empty();
          $("#ddl_STACK").empty();

          $("#ddlEscoms").val(r.ESCOMID);
          console.log("ESCOM set to:", r.ESCOMID);

          $("#ddl_Form_Name").val(r.FORMID);
          console.log("Form set to:", r.FORMID);

          $.ajax({
              url: "Process_Config.aspx/StakeHolders",
              type: "POST",
              contentType: "application/json; charset=utf-8",
              dataType: "json",
              data: JSON.stringify({ ESCOM_ID: r.ESCOMID }),
              success: function (res) {
                  var data = res.d;
                  var ddl = $("#ddl_STACK");
                  ddl.empty();
                  ddl.append('<option value="">-- Select STACKHOLDERS --</option>');

                  if (data && data.length > 0) {
                      $.each(data, function (i, row) {
                          ddl.append(`<option value="${row.ID}">${row.Name}</option>`);
                      });

                      console.log("Stakeholders loaded, total:", data.length);

                      const stackId = r.STACKHOLDER_ID || r.STACKHOLDERID || r.STACKID ||
                          r.STACK_ID || r.StackID || r.Stack_ID;

                      if (stackId) {
                          $("#ddl_STACK").val(stackId);
                          console.log("Stakeholder set to:", stackId, "Name:", $("#ddl_STACK option:selected").text());

                          loadAssignedDesignations(stackId).then(function () {
                              console.log("Designations loaded for edit");

                              
                              const seqIds = (r.SEQUENANCE || r.SEQUENCE || r.Sequence || "").toString().split(",").map(x => x.trim()).filter(x => x);
                              const readIds = (r.PREAD || r.READ || r.Read || "").toString().split(",").map(x => x.trim()).filter(x => x);
                              const writeIds = (r.PWRITE || r.READWRITE || r.ReadWrite || r.WRITE || "").toString().split(",").map(x => x.trim()).filter(x => x);

                              console.log("Sequence IDs:", seqIds);
                              console.log("Read IDs:", readIds);
                              console.log("Write IDs:", writeIds);

                              setTimeout(function () {
                                  $("#ddl_Des_Name option").prop("selected", false);

                                  seqIds.forEach(function (id) {
                                      if (!id) return;

                                      const opt = $("#ddl_Des_Name option[value='" + id + "']");

                                      if (opt.length > 0) {
                                          opt.prop("selected", true);

                                          const name = opt.text();

                                          let access = "Read";
                                          if (writeIds.includes(id)) {
                                              access = "Read/Write";
                                          } else if (readIds.includes(id)) {
                                              access = "Read";
                                          }

                                          console.log("Selected in dropdown - ID:", id, "Name:", name, "Access:", access);
                                      } else {
                                          console.warn("Designation ID not found in dropdown:", id);
                                      }
                                  });

                                  $("#ddl_Des_Name").trigger("change").focus().blur();

                                  var selectElement = document.getElementById("ddl_Des_Name");
                                  if (selectElement) {
                                      selectElement.dispatchEvent(new Event('change'));
                                  }

                                  console.log("Total designations selected:", $("#ddl_Des_Name option:selected").length);

                               
                              }, 300);

                          }).catch(function (err) {
                              console.error("Error loading designations:", err);
                              alert("Error loading designations. Please try again.");
                          });
                      } else {
                          console.warn("No STACKHOLDER_ID found in row data. Available fields:", Object.keys(r));
                          alert("Unable to identify stakeholder from data. Please check the STACKHOLDER_ID field.");
                      }
                  } else {
                      console.error("No stakeholders returned from server");
                      alert("No stakeholders found for this ESCOM");
                  }
              },
              error: function (err) {
                  console.log("Error loading stakeholders:", err);
                  alert("Error fetching Stakeholders!");
              }
          });
      }
  </script>





</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-fluid">

        <div class="card">
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
                    <div class="col-md-8 text-end mt-3 mb-2 pt-1">
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
                    <div class="col-md-3">
                        <label class="form-label">Stackholder's: <span class="text-danger">*</span></label>
                        <select id="ddl_STACK" class="form-select">
                            <option value="">-- Select Stackholder's --</option>
                        </select>
                    </div>
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
                    <div class="col-md-12">
                        <div class="card">
                            <div class="card-header text-center">Granted Designations Summary</div>
                            <div class="card-body">
                                <div id="selectedList"></div>
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

