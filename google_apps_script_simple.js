// Simple approach: Track the last processed row to prevent duplicates
var lastProcessedRow = 0;
var isProcessing = false;

function onEdit(e) {
  if (!e || !e.range || isProcessing) return;

  const sheet = e.range.getSheet();
  const DROPDOWN_COL = 2;
  const DEP_COL = 3;
  const AMOUNT_COL = 4;
  const row = e.range.getRow();
  const col = e.range.getColumn();
  const val = e.range.getValue();
  const oldVal = e.oldValue;

  // Skip if not editing dropdown column (except for totals)
  if (col !== DROPDOWN_COL) {
    if (col === AMOUNT_COL) {
      updateTotals(sheet);
    }
    return;
  }

  // Prevent processing the same row twice in quick succession
  if (lastProcessedRow === row && val === oldVal) {
    return;
  }

  isProcessing = true;
  lastProcessedRow = row;

  try {
    // --- SCENARIO 1: Parent row - Create child when selecting Income/Expense ---
    if (oldVal === "Add New Action" && (val === "Income" || val === "Expense")) {
      const nextRow = row + 1;
      const lastRow = sheet.getLastRow();
      
      // Check if child row already exists
      let childExists = false;
      if (nextRow <= lastRow) {
        const nextRowVal = sheet.getRange(nextRow, DROPDOWN_COL).getValue();
        if (nextRowVal === "Income" || nextRowVal === "Expense") {
          childExists = true;
        }
      }

      if (!childExists) {
        // Insert new row
        sheet.insertRowAfter(row);
        const newRow = row + 1;

        // Configure child row dropdown
        const childCell = sheet.getRange(newRow, DROPDOWN_COL);
        const childRule = SpreadsheetApp.newDataValidation()
          .requireValueInList(["Income", "Expense"], true)
          .setAllowInvalid(false)
          .build();
        childCell.clearDataValidations();
        childCell.setDataValidation(childRule);

        // Temporarily disable processing to set child value
        isProcessing = false;
        childCell.setValue(val);
        SpreadsheetApp.flush();
        Utilities.sleep(300); // Wait for any triggers to complete
        isProcessing = true;

        // Set up dependent dropdown
        const depCell = sheet.getRange(newRow, DEP_COL);
        const sourceRange = val === "Income" 
          ? SpreadsheetApp.getActiveSpreadsheet().getRange('Income')
          : SpreadsheetApp.getActiveSpreadsheet().getRange('Expense');
        
        const listItems = sourceRange.getValues()
          .flat()
          .filter(item => item !== null && item !== '');
        listItems.unshift("Select");
        
        const depRule = SpreadsheetApp.newDataValidation()
          .requireValueInList(listItems, true)
          .setAllowInvalid(false)
          .build();
        depCell.clearDataValidations();
        depCell.setDataValidation(depRule);
        depCell.setValue('Select');
      }

      // Always reset parent to "Add New Action"
      sheet.getRange(row, DROPDOWN_COL).setValue("Add New Action");
      SpreadsheetApp.flush();
      return;
    }

    // --- SCENARIO 2: Child row - Update dependent dropdown when Income/Expense changes ---
    if ((val === "Income" || val === "Expense") && row > 1) {
      const prevRowVal = sheet.getRange(row - 1, DROPDOWN_COL).getValue();
      
      // Only process if previous row is "Add New Action" (meaning this is a child)
      if (prevRowVal === "Add New Action") {
        const depCell = sheet.getRange(row, DEP_COL);
        const sourceRange = val === "Income"
          ? SpreadsheetApp.getActiveSpreadsheet().getRange('Income')
          : SpreadsheetApp.getActiveSpreadsheet().getRange('Expense');
        
        const listItems = sourceRange.getValues()
          .flat()
          .filter(item => item !== null && item !== '');
        listItems.unshift("Select");
        
        const depRule = SpreadsheetApp.newDataValidation()
          .requireValueInList(listItems, true)
          .setAllowInvalid(false)
          .build();
        depCell.clearDataValidations();
        depCell.setDataValidation(depRule);
        depCell.setValue('Select');
        return;
      }
    }

    // Update totals if needed
    if (col === AMOUNT_COL || col === DROPDOWN_COL) {
      updateTotals(sheet);
    }

  } catch (err) {
    Logger.log("Error: " + err.toString());
  } finally {
    isProcessing = false;
    // Reset lastProcessedRow after a delay to allow same row edits later
    Utilities.sleep(100);
    if (lastProcessedRow === row) {
      lastProcessedRow = 0;
    }
  }
}

