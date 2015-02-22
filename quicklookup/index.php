<?
/*
Hello, if possible link to phpfunctions.nfshost.com if you use this source and share your own source. 
No real binding license though.

Requires a DB with this structure:

//START STRUCTURE
CREATE TABLE functions (
  id int(11) NOT NULL auto_increment,
  manual text NOT NULL,
  name text NOT NULL,
  description text NOT NULL,
  use1 text NOT NULL,
  version text NOT NULL,
  searcher text NOT NULL,
  KEY id (id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
 //END STRUCTURE
 
 Full dump available at phpfunctions.nfshost.com


*/


if (isset($_GET['search']))  //If its asking for the AJAX response
{
	$link = mysql_connect('[[[DB ADDRESS]]]', '[[DB USERNAME]]', '[[DB PASSWORD]]'); //Connect to DB
if (!$link) {
   die('Not connected : ');  //CHECK FOR CONNECTION, else die
}


$db_selected = mysql_select_db('[[[DB NAME]]]', $link); //Select name
if (!$db_selected) {
   die ('Can\'t select DB' );  //Die if no DB of that name
}

$searchterm=strtolower($_GET['search']); //Everything lowercase, DB needs to be the same
$searchterm = str_replace("_","\_",$searchterm); //Format underscores correctly for LIKE, otherwise _ = any character
$searchterm3=str_replace("\_","",$searchterm);//This is specifically for PHP, incase people miss out underscores
$sql="(SELECT * FROM functions WHERE name LIKE '$searchterm%' ORDER BY name) UNION (SELECT * FROM functions WHERE name LIKE '%$searchterm%' ORDER BY name) UNION (SELECT * FROM functions WHERE searcher LIKE '%$searchterm3%' ORDER BY name) LIMIT 5";

//Gets firstly whattheytyped????????
//Then ??????whattheytyped?????
//Then ?????w_hat_theyt_yped???? (for PHP, using searcher which is a different field without underscores)


$result=mysql_query($sql); //Do query
$i=1;  //Define $i
while($row=mysql_fetch_assoc($result))  //Get row til end
	{

	?>
<a id="a<?= $i ?>" href="#" onclick="fillin('a<?= $i ?>','<?= $row['description'] ?>','<?= $row['use1'] ?>','<?= $row['version'] ?>','<a href=http://php.net/manual/en/function.<?= $row['manual'] ?>.php target=_blank>View at php.net</a>')"><?= $row['name'] ?></a>, 
<?
$i++;  //Increment for HTML
	}
die(); //Die so HTML below isn't outputted
}
echo '<?xml version="1.0" encoding="iso-8859-1"?>'; //Echo it, cos otherwise it gets confused with <? , its almost valid XHTML apart from autocomplete
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
<title>phpFunctions</title>
<style type="text/css">
a:hover{background:white}
a:link{color:black}
a:visited{color:black}
* {font-family:sans-serif;color:black}
input{background:white;border:1px dashed gray;font-weight:bold;font-size:110%;width:250px;}
div#main{background:white;padding:10px;border:2px solid black}
div#credits{text-align:center; font-size:90%; }

p{margin-top:0;margin-bottom:5px;}
body{background:#9999cc}
h2{margin:0;margin-bottom:5px;}
</style>
<script type="text/javascript">
 <!-- 

function createRequestObject() {  //Get the right xmlHTTP, including IE, FF and Opera, try and catch for errors error catching
	var xmlhttp;
try
    {
        xmlhttp=new ActiveXObject("Msxml2.XMLHTTP");
    }
    catch(e)
    {
        try
        {
             xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
        }
        catch(f)
        {
             xmlhttp=null;
        }
    }
    if(! xmlhttp&&typeof XMLHttpRequest!="undefined")
    {
         xmlhttp=new XMLHttpRequest();
    }
	return  xmlhttp;
}
var http = createRequestObject(); //make the AJAX thingy
var timeoutholder=null; //this variable holds the timeouts which wait between keypresses
function sndReq(search) { //this function asks for the functions
	search=escape(search);  //escape for URLs


try{
    http.open('get', 'index.php?search='+search);  //sends request
    http.onreadystatechange = handleResponse; //ensures the response is handled by the correct function
    http.send(null);}
	catch(e){}
	finally{}

}

function handleResponse() {
	try{
    if((http.readyState == 4)&& (http.status == 200)){
        var response = http.responseText;
            document.getElementById("matches").innerHTML = response; //Fill in response
			document.getElementById("a1").onclick(); //trigger first function to be highlighted
	}
    }

catch(e){
}
finally{}
}
function fillin(button,description,usage,version,manual) {
    
     document.getElementById("description").innerHTML=description;
    document.getElementById("usage").innerHTML=usage;
	document.getElementById("version").innerHTML=version;
	document.getElementById("manual").innerHTML=manual;
for(var i=1;i<6;i++){
	settocolor("a"+i,"white");  //Sets every elements background to white
}

settocolor(button,"yellow"); //Then the selected one to yellow

    }

function settocolor(id,color){ //quick function to set id to a colour
if (document.getElementById(id)!=null)
{
	document.getElementById(id).style.backgroundColor=color;
}
}


function initialise(){//Focuses for ease of use
document.getElementById("search").focus();
}

function getreadytolook(){ //Sets a timeout waiting to look up but cancels it if another key is pressed within 0.4 secs
	var search=document.getElementById("search").value;
		if(timeoutholder!=null)window.clearTimeout(timeoutholder);
	timeoutholder=window.setTimeout("sndReq(\'"+search+"\');", 400);
}
 // -->
</script>
</head>
<body onload="initialise();">
<div id="main">
<h2 style="color:black;text-decoration:underline">phpFunctions</h2>
<noscript>Requires javascript enabled</noscript>
<p><strong>Search:</strong> <input id="search" autocomplete="off" value="" onkeyup="getreadytolook();" /><br /></p>
<p><strong>Matches:</strong> <span id="matches"></span></p>
<p><strong>Description:</strong> <span id="description"></span></p>
<p><strong>Usage:</strong> <span id="usage"></span></p>
<p><strong>Version:</strong> <span id="version"></span></p>
<p><strong>Manual:</strong> <span id="manual"></span></p>
</div>
<div id="credits"><a href=a">About</a><br /><a href="http://php.net">Data from PHP.net</a></div>
</body>
</html>
