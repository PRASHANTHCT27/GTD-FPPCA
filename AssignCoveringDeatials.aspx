<%@ Page Title="" Language="C#" MasterPageFile="~/GTDMaster.master" AutoEventWireup="true" CodeFile="AssignCoveringDeatials.aspx.cs" Inherits="AssignCoveringDeatials" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <script>

        let hotBeneficiary = null;
        let hotCheque = null;
        let selectedBeneficiaryRows = [];

        $(document).ready(function () {
            debugger;

            $("#id1").show();

            $("#divChequeDetails").hide();
            $("#tableContainer").removeClass("d-none");

            $("#txtMonth").on("change", function () {
                GenerateAt();
            });


            $("#btnsave").on("click", handleSave);
            $("#btnSendToPayment").on("click", handleSendToPayment);
            $("#btnRemove").on("click", handleRemove);

            function validateAndShowLoading() {
                debugger;

                var overlay = document.getElementsByClassName("card-overlay")[0];
                overlay.classList.remove("d-none");

                return true;
            }

            $("#txtLetterNo").on("blur", function () {
                let letterNo = $(this).val().trim();
                let month = $("#txtMonth").val().trim();

                if (!letterNo) return;

                $.ajax({
                    type: "POST",
                    url: "AssignCoveringDeatials.aspx/CheckLetterNo",
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    data: JSON.stringify({
                        letterNo: letterNo,
                        month: month
                    }),
                    success: function (response) {
                        let result = response.d;

                        if (!result.success) {
                            showWarningMessage(result.message);
                            $("#txtLetterNo").focus();
                        }
                    },
                    error: function (xhr) {
                        console.log(xhr);
                        showErrorMessage("Error checking letter number");
                    }
                });
            });

        });

        function showLoading() {
            $(".card-overlay").removeClass("d-none");
        }

        function hideLoading() {
            $(".card-overlay").addClass("d-none");
        }
        function resetBeneficiaryTable() {

            const container = document.getElementById('ecrTableContainer');

            if (hotBeneficiary && hotBeneficiary.rootElement) {
                try {
                    hotBeneficiary.destroy();
                } catch (e) { }
                hotBeneficiary = null;
            }

            container.innerHTML = "";

            $("#tableContainer").addClass("d-none");
            $("#addCoverLetterDetails").hide();
            $("#coverletterDetails1").hide();
        }


        function GenerateAt() {
            debugger;

            /* if (hotBeneficiary) {
                 hotBeneficiary.destroy();
             }*/
            /*$("#tableContainer").addClass("d-none");*/

            resetBeneficiaryTable();
            let month = $("#txtMonth").val();

            if (!month) {
                showWarningmessage("Please select Month!");
                return;
            }

            $.ajax({
                type: "POST",
                url: "AssignCoveringDeatials.aspx/FetchDataForGenerateAt",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                data: JSON.stringify({ month: month }),

                success: function (response) {
                    debugger;

                    let result = response.d;

                    console.log(result);

                    if (!result.success) {
                        showWarningmessage("No Data Found");
                        return;
                    }

                    if (result.beneficiaryCount > 0) {

                        result.beneficiaryData.forEach((row, index) => {
                            row.slno = index + 1;
                            row.isSelected = false;
                        });
                        $("#tableContainer").removeClass("d-none");
                        $("#txt_Handson_Table").show();
                        displayBeneficiaryHandsontable(result.beneficiaryData);

                        $("#addCoverLetterDetails").show();
                        $("#coverletterDetails1").show();
                        $("#id1").hide();
                    }
                    else {
                        $("#tableContainer").removeClass("d-none");
                        $("#id1").show();

                        $("#txt_Handson_Table").hide();
                        $("#addCoverLetterDetails").hide();
                        $("#coverletterDetails1").hide();
                        showWarningmessage("No Beneficiary Data Found");
                    }

                    if (result.chequeCount > 0) {
                        $("#id2").hide();
                        result.chequeData.forEach((row, index) => {
                            row.slno = index + 1;
                            row.selected = false;
                        });
                        displayChequeHandsontable(result.chequeData);

                        $("#divChequeDetails").show();
                        $("#buttons").show();
                    }
                    else {
                        $("#id2").show();
                        $("#divChequeDetails").hide();
                        $("#buttons").hide();
                    }
                },

                error: function (xhr) {
                    console.error(xhr);
                    showErrorMessage("Error loading data");
                }
            });
        }


        function displayBeneficiaryHandsontable(data) {
            const container = document.getElementById('ecrTableContainer');

            if (hotBeneficiary) {
                hotBeneficiary.destroy();
            }

            data = data.map((row, index) => ({
                ...row,
                slno: index + 1,
                isSelected: false
            }));

            const centerRenderer = function (instance, td, row, col, prop, value) {
                Handsontable.renderers.TextRenderer.apply(this, arguments);
                td.textContent = value ?? '';
                td.style.textAlign = 'center';
            };

            const rightRenderer = function (instance, td, row, col, prop, value) {
                Handsontable.renderers.TextRenderer.apply(this, arguments);
                td.textContent = value ?? '';
                td.style.textAlign = 'right';
            };

            hotBeneficiary = new Handsontable(container, {
                data: data,
                stretchH: 'all',
                height: 'auto',
                licenseKey: 'non-commercial-and-evaluation',
                rowHeaders: false,
                manualColumnResize: true,

                filters: true,
                dropdownMenu: ['filter_by_condition', 'filter_by_value', 'filter_action_bar'],
                search: true,

                hiddenColumns: { columns: [8], indicators: false },

                colHeaders: [
                    'Select', 'Sl No', 'Beneficiary Name', 'Net Pay',
                    'Beneficiary Bank', 'ACC No', 'IFSC CODE', 'Action', 'BT_SLNO'
                ],

                colWidths: [80, 60, 220, 120, 180, 150, 120, 120, 0],

                columns: [
                    { data: 'isSelected', type: 'checkbox', className: 'htCenter' },
                    { data: 'slno', readOnly: true, renderer: centerRenderer },
                    { data: 'PPA_UNAME', readOnly: true },
                    { data: 'NET_PAYABLE', readOnly: true, type: 'numeric', numericFormat: { pattern: '0,0.00' }, renderer: centerRenderer },
                    { data: 'Name_of_Banks', readOnly: true },
                    { data: 'Account_No', readOnly: true },
                    { data: 'IFSC', readOnly: true },
                    {
                        data: null,
                        readOnly: true,
                        renderer: function (instance, td, row) {
                            Handsontable.dom.empty(td);
                            td.style.textAlign = "center";

                            const btn = document.createElement("button");
                            btn.className = "btn link-primary btn-sm";
                            btn.innerHTML = '<i class="ph-download-simple"></i>';
                            btn.type = "button";

                            btn.onclick = function (e) {
                                e.stopPropagation();
                                const rowData = instance.getSourceDataAtRow(row);
                                const month = $("#txtMonth").val();

                                showLoading();

                                $.ajax({
                                    type: "POST",
                                    url: "AssignCoveringDeatials.aspx/DownloadJV",
                                    contentType: "application/json; charset=utf-8",
                                    data: JSON.stringify({
                                        partAgencyId: rowData.BT_SLNO,
                                        beneficaryName: rowData.PPA_UNAME,
                                        month: month
                                    }),
                                    dataType: "json",
                                    success: function (response) {
                                        hideLoading();
                                        /*const result = JSON.parse(response.d);*/

                                        const result = response.d;

                                        if (result.success) {
                                            showPDFModal(result.pdfData, result.fileName);
                                        } else {
                                            showErrorMessage(result.message || "Error generating PDF");
                                        }
                                    },
                                    error: function () {
                                        hideLoading();
                                        showErrorMessage("Error generating JV PDF");
                                    }
                                });
                            };

                            td.appendChild(btn);
                        }
                    },
                    { data: 'BT_SLNO', readOnly: true }
                ],

                afterGetColHeader: function (col, TH) {
                    if (col !== 0) return;

                    let chk = TH.querySelector("#chkSelectAll");

                    if (!chk) {
                        Handsontable.dom.empty(TH);

                        chk = document.createElement("input");
                        chk.type = "checkbox";
                        chk.id = "chkSelectAll";

                        const span = document.createElement("span");
                        span.style.marginLeft = "4px";
                        span.innerText = "Select";

                        TH.appendChild(chk);
                        TH.appendChild(span);
                    }

                    const totalRows = hotBeneficiary ? hotBeneficiary.countRows() : 0;
                    let checkedCount = 0;

                    if (hotBeneficiary) {
                        for (let r = 0; r < totalRows; r++) {
                            if (hotBeneficiary.getDataAtRowProp(r, "isSelected")) checkedCount++;
                        }
                    }

                    chk.checked = totalRows > 0 && checkedCount === totalRows;

                    if (!chk.dataset.bound) {
                        chk.dataset.bound = "true";

                        chk.addEventListener("change", function () {
                            if (!hotBeneficiary) return; // SAFETY CHECK

                            const checked = this.checked;

                            hotBeneficiary.batch(() => {
                                for (let r = 0; r < hotBeneficiary.countRows(); r++) {
                                    hotBeneficiary.setDataAtRowProp(r, "isSelected", checked);
                                }
                            });

                            hotBeneficiary.render();
                        });
                    }
                }
                ,
                afterChange: function (changes, source) {
                    if (!changes || source === "loadData") return;
                    if (!hotBeneficiary) return;

                    if (changes.some(c => c[1] === "isSelected")) {
                        hotBeneficiary.render();
                    }
                }

            });

            const searchPlugin = hotBeneficiary.getPlugin('search');

            $('#searchBeneficiary').off('keyup').on('keyup', function () {
                searchPlugin.query(this.value);
                hotBeneficiary.render();
            });

            $("#tableContainer").removeClass("d-none");
        }

        function showPDFModal(base64Data, fileName) {

            if (!document.getElementById('pdfViewerModal')) {
                const modalHTML = `
<div class="modal fade" id="pdfViewerModal" tabindex="-1">
  <div class="modal-dialog modal-xl" style="max-width:95%;">
    <div class="modal-content">

      <div class="modal-header">
        <h5 class="modal-title">JV PDF Preview</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>

      <div class="modal-body" style="height:80vh;">
        <iframe id="pdfFrame" style="width:100%; height:100%; border:none;"></iframe>
      </div>

      

    </div>
  </div>
</div>`;
                document.body.insertAdjacentHTML("beforeend", modalHTML);
            }

            const byteCharacters = atob(base64Data);
            const byteNumbers = new Array(byteCharacters.length);
            for (let i = 0; i < byteCharacters.length; i++) {
                byteNumbers[i] = byteCharacters.charCodeAt(i);
            }
            const byteArray = new Uint8Array(byteNumbers);
            const blob = new Blob([byteArray], { type: "application/pdf" });
            const blobUrl = URL.createObjectURL(blob);

            document.getElementById("pdfFrame").src = blobUrl;

          /*  document.getElementById("btnDownloadPDF").onclick = function () {
                const a = document.createElement("a");
                a.href = blobUrl;
                a.download = fileName;
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
            };*/

            const modal = new bootstrap.Modal(document.getElementById("pdfViewerModal"));
            modal.show();

            document.getElementById("pdfViewerModal").addEventListener("hidden.bs.modal", function () {
                URL.revokeObjectURL(blobUrl);
            });
        }


        function displayChequeHandsontable(data) {
            debugger;
            const container = document.getElementById('chequeTableContainer');

            if (hotCheque !== null) {
                hotCheque.destroy();
                hotCheque = null;
                container.innerHTML = "";
            }

            data = data.map((row, index) => ({
                ...row,
                slno: index + 1,
                selected: false
            }));

            const centerRenderer = function (instance, td, row, col, prop, value) {
                Handsontable.renderers.TextRenderer.apply(this, arguments);
                td.textContent = value ?? '';
                td.style.textAlign = 'center';
                td.style.verticalAlign = 'middle';
                td.style.padding = '8px';
                return td;
            };



            const dateRenderer = function (instance, td, row, col, prop, value) {
                Handsontable.renderers.TextRenderer.apply(this, arguments);

                if (!value) {
                    td.textContent = '';
                    return td;
                }

                let date;

                if (typeof value === "string" && value.includes("/Date(")) {
                    const timestamp = parseInt(value.replace(/\/Date\((\d+)\)\//, "$1"));
                    date = new Date(timestamp);
                }
                else {
                    date = new Date(value);
                }

                if (!isNaN(date.getTime())) {
                    const dd = String(date.getDate()).padStart(2, '0');
                    const mm = String(date.getMonth() + 1).padStart(2, '0');
                    const yyyy = date.getFullYear();
                    td.textContent = `${dd}-${mm}-${yyyy}`;
                } else {
                    td.textContent = value;
                }

                td.style.textAlign = 'center';
                td.style.verticalAlign = 'middle';

                return td;
            };



            hotCheque = new Handsontable(container, {
                data: data,
                stretchH: 'all',
                height: Math.min(data.length * 40 + 45, 400),

                licenseKey: 'non-commercial-and-evaluation',
                rowHeaders: false,
                manualColumnResize: true,
                filters: true,
                dropdownMenu: true,
                rowHeights: 40,
                className: 'htMiddle',

                colHeaders: [
                    'Select', 'Sl No', 'Letter No', 'Letter Date', 'Amount', 'Status', 'Action'
                ],
                columns: [
                    { data: 'selected', type: 'checkbox', className: 'htCenter htMiddle' },
                    { data: 'slno', readOnly: true, renderer: centerRenderer, className: 'htMiddle' },
                    { data: 'RECEIPT_NO', readOnly: true, renderer: centerRenderer, className: 'htMiddle' },
                    { data: 'RECEIPT_DATE', readOnly: true, renderer: dateRenderer, className: 'htMiddle' },
                    { data: 'AMOUNT', readOnly: true, renderer: centerRenderer, className: 'htMiddle' },
                    {
                        data: null,
                        readOnly: true,
                        className: 'htMiddle',
                        renderer: function (instance, td, row) {
                            Handsontable.dom.empty(td);

                            td.style.display = "flex";
                            td.style.justifyContent = "center";
                            td.style.alignItems = "center";
                            td.style.height = "100%";
                            td.style.padding = "0";

                            td.innerHTML = `
            <button type="button" class="btn link-primary btn-download-jv" data-row="${row}">
                <i class="ph-download-simple"></i>
            </button>
        `;
                            return td;
                        }
                    }

                ],

                afterGetColHeader: function (col, TH) {
                    if (col !== 0) return;

                    const instance = this;

                    let chk = TH.querySelector("#chkSelectAll");

                    if (!chk) {
                        Handsontable.dom.empty(TH);

                        chk = document.createElement("input");
                        chk.type = "checkbox";
                        chk.id = "chkSelectAll";
                        chk.style.cursor = "pointer";

                        const span = document.createElement("span");
                        span.style.marginLeft = "6px";
                        span.innerText = "Select";

                        TH.appendChild(chk);
                        TH.appendChild(span);

                        chk.onclick = function (e) {
                            e.stopPropagation();

                            const checked = this.checked;

                            instance.batch(() => {
                                for (let r = 0; r < instance.countRows(); r++) {
                                    instance.setDataAtRowProp(r, "selected", checked);
                                }
                            });

                            instance.render();
                        };
                    }

                    const totalRows = instance.countRows();
                    let checkedCount = 0;

                    for (let r = 0; r < totalRows; r++) {
                        if (instance.getDataAtRowProp(r, "selected")) checkedCount++;
                    }

                    chk.checked = totalRows > 0 && checkedCount === totalRows;
                }
                ,

                afterChange: function (changes, source) {
                    if (!changes || source === "loadData") return;

                    if (changes.some(c => c[1] === "selected")) {
                        hotCheque.render();
                    }
                }
            });

            container.addEventListener('click', function (e) {
                const btn = e.target.closest(".btn-download-jv");
                if (!btn) return;

                e.preventDefault();
                e.stopPropagation();

                const rowIndex = parseInt(btn.getAttribute("data-row"), 10);
                const rowData = hotCheque.getSourceDataAtRow(rowIndex);

                console.log("Download JV Row:", rowData);

                handleDownloadJV(rowData);
            });

            $("#chequeTableContainer").removeClass("d-none");
        }


        /* function handleDownloadJV(rowData) {
             if (!rowData || !rowData.RECEIPT_NO) {
                 swal('Error', 'Receipt number is missing', 'error');
                 return;
             }
 
             if (typeof showLoading === 'function') {
                 showLoading();
             }
 
             $.ajax({
                 type: "POST",
                 url: "AssignCoveringDeatials.aspx/GeneratePDF",
                 data: JSON.stringify({ receiptNo: rowData.RECEIPT_NO }),
                 contentType: "application/json; charset=utf-8",
                 dataType: "json",
                 success: function (response) {
                     if (typeof hideLoading === 'function') {
                         hideLoading();
                     }
 
                     if (response && response.d && response.d.success) {
                         if (response.d.pdfData) {
                             showPDFModal(response.d.pdfData, response.d.fileName || 'JV_Report.pdf');
                         } else if (response.d.fileName) {
                             const pdfUrl = '/Files/REGULAR/' + response.d.fileName;
                             showPDFModalFromURL(pdfUrl, response.d.fileName);
                         }
                     } else {
                         swal('Error', response.d?.message || 'Failed to generate PDF', 'error');
                     }
                 },
                 error: function (xhr, status, error) {
                     if (typeof hideLoading === 'function') {
                         hideLoading();
                     }
                     swal('Error', 'Server error while generating PDF: ' + error, 'error');
                 }
             });
         }*/


        function showPDFModal(base64Data, fileName) {
            if (!document.getElementById('pdfViewerModal')) {
                const modalHTML = `
<div class="modal fade" id="pdfViewerModal" tabindex="-1">
  <div class="modal-dialog modal-xl" style="max-width:95%;">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title">PDF Preview - ${fileName}</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body" style="height:80vh;">
        <iframe id="pdfFrame" style="width:100%; height:100%; border:none;"></iframe>
      </div>
      
    </div>
  </div>
</div>`;
                document.body.insertAdjacentHTML("beforeend", modalHTML);
            }

            const byteCharacters = atob(base64Data);
            const byteNumbers = new Array(byteCharacters.length);
            for (let i = 0; i < byteCharacters.length; i++) {
                byteNumbers[i] = byteCharacters.charCodeAt(i);
            }
            const byteArray = new Uint8Array(byteNumbers);
            const blob = new Blob([byteArray], { type: "application/pdf" });
            const blobUrl = URL.createObjectURL(blob);

            document.getElementById("pdfFrame").src = blobUrl;

           /* document.getElementById("btnDownloadPDF").onclick = function () {
                const a = document.createElement("a");
                a.href = blobUrl;
                a.download = fileName;
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
            };*/

            const modal = new bootstrap.Modal(document.getElementById("pdfViewerModal"));
            modal.show();

            document.getElementById("pdfViewerModal").addEventListener("hidden.bs.modal", function () {
                URL.revokeObjectURL(blobUrl);
            }, { once: true });
        }

        function handleTableClick(e) {
            debugger;
            const btn = e.target.closest('.btn-download-jv');
            if (btn) {
                e.preventDefault();
                e.stopPropagation();
                const row = parseInt(btn.getAttribute('data-row'), 10);
                const rowData = hotCheque.getSourceDataAtRow(row);
                handleDownloadJV(rowData);
            }
        }

        function handleDownloadJV(rowData) {

            if (!rowData || !rowData.RECEIPT_NO) {
                showErrorMessage('Receipt number is missing');
                return;
            }

            $.ajax({
                type: "POST",
                url: "AssignCoveringDeatials.aspx/GeneratePDF",
                data: JSON.stringify({ receiptNo: rowData.RECEIPT_NO }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (response) {

                    if (response && response.d && response.d.success) {

                        var base64Data = response.d.pdfData;
                        var fileName = "JV_" + rowData.RECEIPT_NO + ".pdf";

                        showPDFModal(base64Data, fileName);

                    } else {
                        showErrorMessage('Failed to generate PDF');
                    }
                },
                error: function () {
                    showErrorMessage('Error', 'Server error while generating PDF', 'error');
                }
            });
        }


        function getSelectedBeneficiaries() {
            if (!hotBeneficiary) return [];

            const sourceData = hotBeneficiary.getSourceData();

            return sourceData.filter(row => row.isSelected === true);
        }

        function handleSave() {
            debugger;
            const letterNo = $("#txtLetterNo").val().trim();
            const letterDate = $("#txtLetterDate").val().trim();
            const selectedBeneficiaries = getSelectedBeneficiaries();

            if (!letterNo) {
                showWarningmessage("Please enter Letter No");
                return;
            }

            if (!letterDate) {
                showWarningmessage("Please enter Letter Date");
                return;
            }

            if (selectedBeneficiaries.length === 0) {
                showWarningmessage("Please select at least one beneficiary");
                return;
            }

            saveCoverLetterDetails(letterNo, letterDate, selectedBeneficiaries);
        }

        function saveCoverLetterDetails(letterNo, letterDate, beneficiaries) {
            debugger;
            showLoading();

            let month = $("#txtMonth").val();
            if (!month) {
                showWarningmessage("Please Select Month");
                return;
            }

            $.ajax({
                type: "POST",
                url: "AssignCoveringDeatials.aspx/SaveCoverLetterDetails",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                data: JSON.stringify({
                    letterNo: letterNo,
                    letterDate: letterDate,
                    beneficiaries: beneficiaries,
                    Month: month
                }),
                success: function (response) {
                    hideLoading();

                    let result = response.d;

                    if (result.success) {
                        showSuccessMessage("Data Saved Successfully");
                        $("#txtLetterNo").val('');
                        $("#txtLetterDate").val('');
                        setTimeout(function () {
                            GenerateAt();
                        }, 1000);

                    } else {
                        showWarningMessage(result.message);
                    }
                },
                error: function (xhr) {
                    hideLoading();
                    console.error(xhr.responseText);
                    showErrorMessage("Error saving data");
                }
            });
        }

        function handleRemove() {
            debugger;
            const selectedCheques = getSelectedCheques();

            if (selectedCheques.length === 0) {
                showWarningmessage("Please select at least one covering letter to remove");
                return;
            }

            showLoading();

            $.ajax({
                type: "POST",
                url: "AssignCoveringDeatials.aspx/RemoveCoveringLetters",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                data: JSON.stringify({
                    cheques: selectedCheques
                }),
                success: function (response) {
                    hideLoading();

                    let result = response.d;
                    if (result.success) {
                        showSuccessMessage("Successfully removed!");
                        GenerateAt();
                    } else {
                        showWarningmessage("Error: " + result.message);
                    }
                },
                error: function (xhr) {
                    hideLoading();
                    console.error(xhr);
                    showWarningmessage("Error removing letters");
                }
            });
        }


        function DeleteGenPdfFile() {
            $.ajax({
                type: "POST",
                url: "AssignCoveringDeatials.aspx/DeleteFiles",
                data: '{}',
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (response) {
                    console.log("Files deleted successfully");
                },
                error: function (xhr) {
                    console.error("Error deleting files:", xhr);
                }
            });
        }


        function handleSendToPayment() {
            debugger;
            const selectedCheques = getSelectedCheques();

            if (selectedCheques.length === 0) {
                showWarningmessage("Please select at least one covering letter to send to payment");
                return;
            }

            showLoading();

            $.ajax({
                type: "POST",
                url: "AssignCoveringDeatials.aspx/SendToPayment",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                data: JSON.stringify({ cheques: selectedCheques }),
                success: function (response) {
                    hideLoading();

                    let result = response.d;

                    if (result.success) {
                        showSuccessMessage("record(s) Sent successfully");
                        GenerateAt();
                    } else {
                        showWarningMessage(result.message);
                    }
                },
                error: function (xhr) {
                    hideLoading();
                    console.error(xhr.responseText);
                    showWarningMessage("Error sending to payment");
                }
            });
        }


        function getSelectedCheques() {
            if (!hotCheque) return [];

            return hotCheque.getSourceData()
                .filter(r => r.selected === true)
                .map(r => ({
                    RECEIPT_NO: r.RECEIPT_NO,
                    ESCOMS: r.ESCOMS || "HESCOM"
                }));
        }


        /*function getSelectedBeneficiaries() {
            if (!hotBeneficiary) return [];

            return hotBeneficiary.getSourceData()
                .filter(r => r.isSelected === true);
        }*/



    </script>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="Server">
    <asp:HiddenField ID="hidgrid" runat="server" />

    <div class="container-fluid">
        <div class="card-overlay custom-loader d-none">
            <span class="spinner-border spinner"></span>
        </div>

        <div class="card mt-2">
            <div class="card-header d-flex align-items-center">
                <h6 class="mb-0">Assign Covering Letter</h6>
            </div>

            <div class="card-body">

                <div class="row mb-3">
                    <div class="col-md-3">
                        <label class="form-label fw-bold">Month-Year<span class="text-danger">*</span></label>
                        <div class="input-group">
                            <span class="input-group-text"><i class="ph-calendar"></i></span>
                            <input type="text" id="txtMonth" onkeydown="return false"
                                class="form-control datepicker-pick-level_Month_Default_PastMonth"
                                placeholder="MM-YYYY" />
                        </div>
                    </div>
                </div>

                <div class="fw-bold border-bottom pb-2 mb-3">
                    Assign Covering Details
                </div>

                <div id="tableContainer" class="d-none mb-3">
                    <div class="dataTables_wrapper dt-bootstrap5 no-footer">

                        <%--<div class="row mb-2">
                            <div class="col-md-4">
                                <label class="fw-bold">Filter:</label>
                                <div class="form-control-feedback form-control-feedback-end">
                                    <input type="search" id="searchInput" class="form-control"
                                        placeholder="Type to filter..." aria-controls="energyTable">
                                    <div class="form-control-feedback-icon">
                                        <i class="ph-magnifying-glass opacity-50"></i>
                                    </div>
                                </div>
                            </div>
                        </div>--%>

                        <div id="txt_Handson_Table">
                            <div id="ecrTableContainer"></div>
                        </div>

                    </div>

                    <table border="1" width="100%" cellpadding="8" cellspacing="0" id="id1">
                        <tr>
                            <td align="center">
                                <b>No Data Found</b>
                            </td>
                        </tr>
                    </table>

                </div>

                <div class="row" id="coverletterDetails1" style="display: none;">

                    <div class="col-md-3 mb-3">
                        <label class="fw-bold">Letter No<span class="text-danger">*</span></label>
                        <input type="text" id="txtLetterNo" class="form-control" placeholder="Letter No" />
                    </div>

                    <div class="col-md-3 mb-3">
                        <label class="fw-bold">Letter Date<span class="text-danger">*</span></label>
                        <div class="input-group">
                            <span class="input-group-text"><i class="ph-calendar"></i></span>
                            <input type="text" id="txtLetterDate"
                                class="form-control datepicker-date-format_default_Past"
                                placeholder="Pick a date" readonly />
                        </div>
                    </div>

                    <div class="col-md-6 d-flex align-items-end justify-content-end mb-3">
                        <button type="button" id="btnsave" class="btn btn-success px-4">
                            Save
                        </button>
                    </div>

                </div>

                <div class="fw-bold border-bottom pb-2 mb-3">
                    Covering Details
                </div>

                <div id="divChequeDetails" class="mb-3">
                    <div id="chequeTableContainer"></div>
                </div>

                <table border="1" width="100%" cellpadding="8" cellspacing="0" id="id2">
                    <tr>
                        <td align="center">
                            <b>No Data Found</b>
                        </td>
                    </tr>
                </table>

                <div class="row" id="buttons" style="display: none;">
                    <div class="col-md-12 d-flex justify-content-end gap-2">
                        <button type="button" id="btnSendToPayment" class="btn btn-success px-3">
                            <i class="ph ph-paper-plane-tilt me-1"></i>Send To Payment
                        </button>
                        <button type="button" id="btnRemove" class="btn btn-outline-dark px-3">
                            <i class="ph ph-trash me-1"></i>Remove
                        </button>
                    </div>
                </div>

            </div>
        </div>
    </div>
</asp:Content>


