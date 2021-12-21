*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Excel.Files
Library           RPA.Robocorp.Vault
Library           RPA.Tables
Library           Dialogs
Library           RPA.Archive
Library           String
Library           OperatingSystem
Library           RPA.Dialogs

*** Keywords ***
Get orders
    [Arguments]    ${url_csv}
    Download    ${url_csv}    overwrite=True
    ${tbl_orders}=    Read table from CSV    orders.csv
    [Return]    ${tbl_orders}

Open the robot order website
    [Arguments]    ${url_web}
    Open Available Browser    ${url_web}

Close the annoying modal
    Wait Until Element Is Visible    css:div.modal
    Click Button    css:button.btn-dark

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath:/html/body/div[1]/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    preview

Submit the order
    Click Button    order
    ${exist_element}    Is Element Visible    id:order-completion
    Log    ${exist_element}
    IF    ${exist_element} == False
        Reload Page
        Continue For Loop
    END

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${order_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_results_html}    ${OUTPUT_DIR}${/}receipts${/}${order_number}.pdf
    [Return]    ${OUTPUT_DIR}${/}receipts${/}${order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}receipts${/}${order_number}.png
    [Return]    ${OUTPUT_DIR}${/}receipts${/}${order_number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${img_robot}    ${pdf_order}
    ${files}=    Create List
    ...    ${img_robot}:align=center,width=50%,height=50%
    Add Files To Pdf    ${files}    ${pdf_order}    True
    Remove File    ${img_robot}

Go to order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    Close Browser
    ${input_test}=    Input Filename
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}PDFs.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${zip_file_name}

Input Filename
    Add heading    Send FilaName Zip
    Add text input    filename    label=Filename (Without .zip)
    ${result}=    Run dialog
    [Return]    ${result.filename}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Input Filename
    ${url}=    Get Secret    url
    Open the robot order website    ${url}[web]
    ${orders}=    Get orders    ${url}[csv]
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
