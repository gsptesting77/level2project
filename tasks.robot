*** Settings ***
Documentation        Orders robots from RobotSpareBin Industries Inc.
...                  Saves the order HTML receipt as a PDF file.
...                  Saves the screenshot of the ordered robot.
...                  Embeds the screenshot of the robot to the PDF receipt.
...                  Creates ZIP archive of the receipts and the images.
Library              RPA.Browser.Selenium
Library              RPA.HTTP
Library              RPA.Tables
Library              RPA.PDF
Library              RPA.RobotLogListener
Library              RPA.FileSystem
Library              Collections
Library              RPA.Robocloud.Secrets
Library              RPA.Archive
Library              RPA.Dialogs

*** Variables ***
${MAX_ATTEMPTS}=     10
${output_folder}=    ${CURDIR}${/}output

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${shallwe}=                                           Ask Human Input
    IF                                                    ${shallwe}
    ${orders}=                                            Get orders
    Open the robot order website
    FOR                                                   ${row}                                                              IN                                             @{orders}
    Close the annoying modal
    Fill the form                                         ${row}
    Preview the robot
    Submit the order
    ${pdf}=                                               Store the receipt as a PDF file                                     ${row}[Order number]
    ${screenshot}=                                        Take a screenshot of the robot                                      ${row}[Order number]
    Embed the robot screenshot to the receipt PDF file    ${screenshot}                                                       ${pdf}
    Go to order another robot
    END
    Create a ZIP file of the receipts
    END

*** Keywords ***
Ask Human Input
    ${shallwe}                                            Set Variable                                                        False
    Add icon                                              Warning
    Add heading                                           Shall we get the orders and place them all?
    ${download_file}=                                     Get Secret                                                          MySecret
    Add Text                                              ${download_file}[orders_csv_url]                                    size=Small
    Add submit buttons                                    buttons=Okay,No                                                     default=Okay
    ${user}=                                              Run dialog                                                          title=ROBOT
    IF                                                    $user.submit == "Okay"
    ${shallwe}                                            Set Variable                                                        True
    END
    [return]                                              ${shallwe}

Download The CSV File
    ${download_file}=                                     Get Secret                                                          MySecret
    Download                                              ${download_file}[orders_csv_url]                                    overwrite=True

Open the robot order website
    ${website}=                                           Get Secret                                                          MySecret
    Open Available Browser                                ${website}[website_url]

Get orders
    Download The CSV File
    ${orders}=                                            Read table from CSV                                                 orders.csv
    Log                                                   Found columns: ${orders.columns}
    [return]                                              ${orders}

Close the annoying modal
    ${modal}=                                             Run keyword And Return Status                                       Wait Until Page Contains Element               class:modal-content       timeout=3       error=false
    IF                                                    ${modal}
    Click Button                                          OK
    END

Fill the form
    [Documentation]                                       Fill every fields in the page.
    [Arguments]                                           ${row}
    Select From List By Value                             id:head                                                             ${row}[Head]
    Select Radio Button                                   body                                                                ${row}[Body]
    Input Text                                            xpath://input[@placeholder='Enter the part number for the legs']    ${row}[Legs]
    Input Text                                            id:address                                                          ${row}[Address]


Preview the robot
    Click Button                                          id:preview
    FOR                                                   ${i}                                                                IN RANGE                                       ${MAX_ATTEMPTS}
    ${preview}=                                           Run keyword And Return Status                                       Wait Until Element Is Visible                  id:robot-preview-image
    IF                                                    ${preview} == True
    Exit For Loop If                                      True
    ELSE
    Click Button                                          id:preview
    Sleep                                                 1
    END
    END

Submit the order
    Click Button                                          id:order
    FOR                                                   ${i}                                                                IN RANGE                                       ${MAX_ATTEMPTS}
    ${submit}=                                            Run keyword And Return Status                                       Wait Until Element Is Visible                  id:receipt
    IF                                                    ${submit} == True
    Exit For Loop If                                      True
    ELSE
    Click Button                                          id:order
    Sleep                                                 1
    END
    END

Store the receipt as a PDF file
    [Arguments]                                           ${order_num}
    ${sales_receipt_html}=                                Get Element Attribute                                               id:receipt                                     outerHTML
    Html To Pdf                                           ${sales_receipt_html}                                               ${output_folder}${/}recipt_${order_num}.pdf
    [return]                                              ${output_folder}${/}recipt_${order_num}.pdf

Take a screenshot of the robot
    [Arguments]                                           ${order_num}
    Screenshot                                            id:robot-preview-image                                              ${output_folder}${/}image_${order_num}.png
    [return]                                              ${output_folder}${/}image_${order_num}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]                                           ${screenshot}                                                       ${pdf}
    Add Watermark Image To PDF                            image_path=${screenshot}                                            source_path=${pdf}                             output_path=${pdf}        coverage=0.2
    Close Pdf                                             ${pdf}

Go to order another robot
    Click Button                                          id:order-another

Create a ZIP file of the receipts
    Archive Folder With Zip                               ${output_folder}                                                    ${output_folder}${/}Archive.zip                include=*.pdf
