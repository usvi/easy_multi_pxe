<?php
if ((!array_key_exists('method', $_GET)) ||
    (!array_key_exists('family', $_GET)) ||
    (!array_key_exists('version', $_GET)) ||
    (!array_key_exists('arch', $_GET)) ||
    (!array_key_exists('id', $_GET)))
{
    exit(0);
}
if ((strlen($_GET['method']) == 0) ||
    (strlen($_GET['family']) == 0) ||
    (strlen($_GET['version']) == 0) ||
    (strlen($_GET['arch']) == 0) ||
    (strlen($_GET['id']) == 0))
{
    exit(0);
}
     
$os_method = $_GET['method'];
$os_family = $_GET['family'];
$os_version = $_GET['version'];
$os_arch = $_GET['arch'];
$os_id = $_GET['id'];

?>
