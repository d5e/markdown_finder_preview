on run argv
    set fixturePath to item 1 of argv
    tell application "System Events" to tell process "Finder"
        if exists window "Quick Look" then error "Close the open Finder Quick Look window before running this test"
    end tell
    tell application "Finder"
        set fixture to POSIX file fixturePath as alias
        activate
        set testWindow to make new Finder window
        set target of testWindow to container of fixture
        select fixture
        set selectedFiles to get selection
        if (count of selectedFiles) is not 1 then error "Finder did not select the fixture"
    end tell
    try
        tell application "System Events" to tell process "Finder"
            set frontmost to true
            set fileMenu to menu 1 of menu bar item "File" of menu bar 1
            set itemNames to name of every menu item of fileMenu
            repeat with itemName in itemNames
                if itemName is not missing value and itemName starts with "Quick Look" then
                    click menu item (itemName as text) of fileMenu
                    exit repeat
                end if
            end repeat
            repeat 40 times
                if (exists static text "Markdown Finder Smoke.md" of window "Quick Look") and ¬
                    (exists radio button "Preview" of radio group 1 of window "Quick Look") then exit repeat
                delay 0.25
            end repeat
            set previewWindow to window "Quick Look"
            if not (exists static text "Markdown Finder Smoke.md" of previewWindow) then error "Unexpected preview file"
            set modes to radio group 1 of previewWindow
            if value of radio button "Preview" of modes is not 1 then error "Preview is not selected by default"
            click radio button "Source" of modes
            if value of radio button "Source" of modes is not 1 then error "Source did not select"
            click radio button "Preview" of modes
            if value of radio button "Preview" of modes is not 1 then error "Preview did not reselect"
            click (first button of previewWindow whose subrole is "AXCloseButton")
        end tell
        tell application "Finder" to close testWindow
    on error messageText number errorNumber
        tell application "Finder" to close testWindow
        error messageText number errorNumber
    end try
    return "PASS Finder defaults to Preview and switches between Preview and Source"
end run
