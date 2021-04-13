<?php
 if(isset($_POST['submit']))
 {
   $output=shell_exec('sh list-aws-resource-all-region.sh');
   echo $output;
 }
?>

<form action="" method="post">
<input type="submit" name="submit" value="List AWS Resources">
</form>
