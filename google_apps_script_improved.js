var forceStop = false;
var ignoreOnEdit = false;

function onEdit(e) {
  // Prevent execution if force stop is active or if we're ignoring edits
  if (!e || ignoreOnEdit || forceStop) return;

  const sheet = e.range.getSheet();
  const DROPDOWN_COL = 2; // Column B (parent/child type)
  const DEP_COL = DROPDOWN_COL + 1; // Column C (dependent dropdown)
  const AMOUNT_COL = 4;   // Column D
  const row = e.range.getRow();
  const col = e.range.getColumn();
  const val = e.range.getValue();
  const oldVal = e.oldValue;

  // Set flags immediately to prevent re-triggering
  ignoreOnEdit = true;
  forceStop = true;

  try {
    const parentCell = sheet.getRange(row, DROPDOWN_COL);

    // --- Parent row: create child row when user selects Income/Expense ---
    if (col === DROPDOWN_COL && oldVal === "Add New Action" && (val === "Income" || val === "Expense")) {
      const newRow = row + 1;

      // Insert row first
      sheet.insertRowAfter(row);
      
      // Small delay to ensure row is inserted
      SpreadsheetApp.flush();
      Utilities.sleep(100);

      // Child dropdown (Income/Expense)
      const childCell = sheet.getRange(newRow, DROPDOWN_COL);
      const childRule = SpreadsheetApp.newDataValidation()
        .requireValueInList(["Income", "Expense"])
        .setAllowInvalid(false)
        .build();
      childCell.clearDataValidations();
      childCell.setDataValidation(childRule);
      
      // Set value with ignoreOnEdit flag to prevent re-trigger
      ignoreOnEdit = true;
      childCell.setValue(val);
      SpreadsheetApp.flush();
      Utilities.sleep(50);

      // Dependent dropdown for child
      const depCell = sheet.getRange(newRow, DEP_COL);
      const listItems = val === "Income"
        ? SpreadsheetApp.getActiveSpreadsheet().getRange('Income').getValues().flat()
        : SpreadsheetApp.getActiveSpreadsheet().getRange('Expense').getValues().flat();
      listItems.unshift("Select");
      
      const depRule = SpreadsheetApp.newDataValidation()
        .requireValueInList(listItems, true)
        .setAllowInvalid(false)
        .build();
      depCell.clearDataValidations();
      depCell.setDataValidation(depRule);
      
      // Set value with ignoreOnEdit flag
      ignoreOnEdit = true;
      depCell.setValue('Select');
      SpreadsheetApp.flush();
      Utilities.sleep(50);

      // Reset parent dropdown with ignoreOnEdit flag
      ignoreOnEdit = true;
      parentCell.setValue("Add New Action");
      SpreadsheetApp.flush();
      Utilities.sleep(50);
      
      // Reset flags after all operations
      forceStop = false;
      ignoreOnEdit = false;
      return;
    }

    // --- Update dependent dropdown for child row whenever its dropdown changes ---
    // Only update dependent dropdown for child rows
    if (col === DROPDOWN_COL && (val === "Income" || val === "Expense")) {
      const currentParentValue = parentCell.getValue();
      
      // Skip if current row is parent (value "Add New Action")
      if (currentParentValue === "Add New Action") {
        ignoreOnEdit = false;
        forceStop = false;
        return;
      }

      // Now apply dependent dropdown only to child
      const depCell = sheet.getRange(row, DEP_COL);
      const listItems = val === "Income"
        ? SpreadsheetApp.getActiveSpreadsheet().getRange('Income').getValues().flat()
        : SpreadsheetApp.getActiveSpreadsheet().getRange('Expense').getValues().flat();
      listItems.unshift("Select");
      
      const depRule = SpreadsheetApp.newDataValidation()
        .requireValueInList(listItems, true)
        .setAllowInvalid(false)
        .build();
      depCell.clearDataValidations();
      depCell.setDataValidation(depRule);
      
      // Clear previous selection
      ignoreOnEdit = true;
      depCell.setValue('Select');
      SpreadsheetApp.flush();
      Utilities.sleep(50);
    }

    // --- Update totals if necessary ---
    if (col === AMOUNT_COL || col === DROPDOWN_COL) {
      updateTotals(sheet);
    }

  } catch (err) {
    Logger.log("Error: " + err);
  } finally {
    // Always reset flags in finally block
    ignoreOnEdit = false;
    forceStop = false;
  }
}

function updateTotals(sheet) {
  // Add your totals update logic here
  // This is a placeholder function
}
