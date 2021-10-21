*** Settings ***
<<<<<<< HEAD
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
=======
Documentation          Orders robots from RobotSpareBin Industries Inc.
...                    Saves the order HTML receipt as a PDF file.
...                    Saves the screenshot of the ordered robot.
...                    Embeds the screenshot of the robot to the PDF receipt.
...                    Creates ZIP archive of the receipts and the images.
Library                RPA.Browser.Selenium
Library                RPA.PDF
Library                RPA.Archive
Library                RPA.Tables
Library                RPA.HTTP
Library                RPA.Dialogs
Library                RPA.Robocloud.Secrets

*** Variables ***
${orders_file_url}=    https://robotsparebinindustries.com/orders.csv
${website_url}=        https://robotsparebinindustries.com/#/robot-order

*** Tasks ***
Orders robots from RobotSpareBin Industries Inc.
    Open the robot order website
    ${order_path}=                                        Collect order location
    ${orders}=                                            Get orders                                                          ${order_path}
    FOR                                                   ${order}                                                            IN                                                                               @{orders}
    Close Modal
    Fill Form                                             ${order}
    Preview the Robot
    Submit the order
    ${pdf}=                                               Store the receipt as a PDF file                                     ${order}
    ${screenshot}=                                        Take a screenshot of the robot                                      ${order}
    Embed the robot screenshot to the receipt PDF file    ${screenshot}                                                       ${pdf}
    Go to order another robot
    END
    Create Zip file of the receipts

*** Keywords ***
Open the robot order website
    [Documentation]                                       Open Order Website with Available browser
    ${website}=                                           Get Secret                                                          website
    Open Available Browser                                ${website}[site_url]

Get orders
    [Arguments]                                           ${order_path}
    Log                                                   Get orders
    Download                                              ${order_path}                                                       overwrite=True
    ${orders}=                                            Read table from CSV                                                 orders.csv                                                                       header=True
    [Return]                                              ${orders}

Close Modal
    Log                                                   Close Modal
    Click Element When Visible                            xpath://button[normalize-space()='OK']

Fill Form
    [Documentation]                                       Fill every fields in the page.
    [Arguments]                                           ${order}
    Log                                                   Fill Form
    Select From List By Value                             id:head                                                             ${order}[Head]
    Select Radio Button                                   body                                                                ${order}[Body]
    Input Text                                            xpath://input[@placeholder='Enter the part number for the legs']    ${order}[Legs]
    Input Text                                            id:address                                                          ${order}[Address]

Preview the Robot
    [Documentation]                                       Click on Preview Button
    Log                                                   Get orders
    Click Button                                          id:preview

Submit the order
    [Documentation]                                       Click on Order Button
    Log                                                   Submit the order
    Wait Until Keyword Succeeds                           10x                                                                 1s                                                                               Assert Order Success

Assert Order Success
    Click Button                                          id:order
    Wait Until Element Is Visible                         id:receipt

Store the receipt as a PDF file
    [Arguments]                                           ${order}
    Log                                                   Store the receipt as a PDF file
    Set Local Variable                                    ${OrderNumber}                                                      ${order}[Order number]
    ${folders}=                                           Get Secret                                                          output_folders
    ${receipt_html}=                                      Get Element Attribute                                               id:receipt                                                                       outerHTML
    Set Local Variable                                    ${path_receipt}                                                     ${CURDIR}${/}output${/}${folders}[receipts]${/}OrderNumber_${OrderNumber}.pdf
    Html To Pdf                                           ${receipt_html}                                                     ${path_receipt}
    [Return]                                              ${path_receipt}

Take a screenshot of the robot
    [Arguments]                                           ${order}
    Log                                                   Take a screenshot of the robot
    ${folders}=                                           Get Secret                                                          output_folders
    Set Local Variable                                    ${OrderNumber}                                                      ${order}[Order number]
    Set Local Variable                                    ${path_screen}                                                      ${CURDIR}${/}output${/}${folders}[images]${/}OrderNumber_${OrderNumber}.png
    Sleep                                                 2
    Capture Element Screenshot                            id:robot-preview-image                                              ${path_screen}
    [Return]                                              ${path_screen}

Embed the robot screenshot to the receipt PDF file
    [Arguments]                                           ${screenshot}                                                       ${pdf}
    Add Watermark Image To Pdf                            ${screenshot}                                                       ${pdf}                                                                           ${pdf}

Go to order another robot
    [Documentation]                                       Click on Order Another Robot Button
    Click Button                                          id:order-another

Create Zip file of the receipts
    Archive Folder With Zip                               ${CURDIR}${/}output${/}receipts                                     ${CURDIR}${/}output${/}Archive.zip

Collect order location
    Add heading                                           Shall we begin placing orders?
    Add text                                              Let get the orders from ${orders_file_url}                          size=Small
    Add radio buttons
    ...                                                   name=order_location
    ...                                                   options=${orders_file_url},Dummy
    ...                                                   default=${orders_file_url}
    ...                                                   label=URL
    ${result}=                                            Run dialog                                                          title=orders.csv                                                                 height=400              width=480
    [Return]                                              ${result.order_location}
>>>>>>> initial commit
