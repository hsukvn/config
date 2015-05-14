#!/usr/bin/php
<?php

//$JRE = "/usr/local/jre/bin/java";
$JRE = "java";
$JSLINT = "/usr/local/tool/jslint+rhino.jar";
$RhinoCompressor = "/usr/local/tool/custom_rhino.jar";
$ClosureCompiler = "/usr/local/tool/closurecompiler.jar";
$YUICompressor = "/usr/local/tool/yuicompressor-2.4.2.jar";
$VerboseMsg = false;

$COPYRIGHT = "/* Copyright (c) " . date("Y") . " Synology Inc. All rights reserved. */\n\n";

$JSLINT_IGNORE = array("variable .* declared in a block",
						".* is better written in dot notation",
						"Use .* to compare with",
						"Line breaking error",
						"A constructor name should start with an uppercase letter",
						"Missing 'new' prefix when invoking a constructor",
						"Use the array literal notation*",
						"JavaScript URL.",
						"document.write",
						"eval");


function ShouldIgnoreJSLintError($desc)
{
	global $JSLINT_IGNORE;
	foreach($JSLINT_IGNORE as $pattern) {
		if (ereg($pattern, $desc)) {
			return true;
		}
	}
	return false;
}

function ValidateJSFiles($jsFiles) {
	global $JRE, $JSLINT, $VerboseMsg;

	$errors = 0;
	$fileList = implode(' ', $jsFiles);

	$cmd = sprintf("%s -jar %s %s", $JRE, $JSLINT, $fileList);

	$handle = popen($cmd, "r");
	while (!feof($handle)) {
		$line = fgets($handle);
		$line = trim($line);
		if (!$line) {
			continue;
		}
		list($prog, $file, $lineno, $err, $desc) = explode(":", $line);
		$invalidLine = !ShouldIgnoreJSLintError($desc);
		if ($invalidLine) {
			$errors++;
		}
		if ($invalidLine || $VerboseMsg) {
			echo $line ."\n";
		}
	}
	pclose($handle);
	return $errors;
}

function CombineJSFiles($outFile, $jsFiles)
{
	foreach ($jsFiles as $file) {
		file_put_contents($outFile, file_get_contents($file), FILE_APPEND);
	}
}

function RhinoCompress($outFile, $jsFile)
{
	global $JRE, $RhinoCompressor;
	$cmd = sprintf("%s -jar %s -c %s",
				   escapeshellcmd($JRE), escapeshellarg($RhinoCompressor),
				   escapeshellarg($jsFile));
	$handle = popen($cmd, "r");

	/* custom_rhino.jar won't trim line-break */
	$fp = fopen($outFile, "a");
	while (!feof($handle)) {
		fwrite($fp, trim(fgets($handle)));
	}
	fclose($fp);

	pclose($handle);
}

function ClosureCompile($outFile, $jsFile)
{
	global $JRE, $ClosureCompiler;
	$cmd = sprintf("%s -jar %s --warning_level QUIET --js %s >>%s",
				   escapeshellcmd($JRE), escapeshellarg($ClosureCompiler),
				   escapeshellarg($jsFile), escapeshellarg($outFile));
	system($cmd);
}

function YUICompress($outFile, $jsFile)
{
	global $JRE, $YUICompressor;
	$cmd = sprintf("%s -jar %s %s >>%s",
				   escapeshellcmd($JRE), escapeshellarg($YUICompressor),
				   escapeshellarg($jsFile), escapeshellarg($outFile));
	system($cmd);
}

function CompressJSFiles($compressor, $outFile, $jsFiles)
{
	global $COPYRIGHT;

	file_put_contents($outFile, $COPYRIGHT);

	$tmpFile = '.jsTmp_' . microtime(true) . '.js';
	@unlink($tmpFile);
	CombineJSFiles($tmpFile, $jsFiles);
	$compressor($outFile, $tmpFile);
	@unlink($tmpFile);
}

function GetOptions()
{
	global $argv;

	$options = "svc:";
	$opts = getopt($options);
	foreach( $opts as $o => $a )
	{
		while ( $k = array_search( "-" . $o, $argv ) ) {
			if ( $k )
				unset( $argv[$k] );
			if ( preg_match( "/^.*".$o.":.*$/i", $options ) )
				unset( $argv[$k+1] );
		}
	}
	$argv = array_merge( $argv );
	return $opts;
}

function ShowMessage($msg)
{
	global $VerboseMsg;

	if (!$VerboseMsg) {
		return;
	}
	echo $msg . "\n";
}

function Usage()
{
	global $argv;

	echo <<<EOD
{$argv[0]} [-s] [-c rhino|closure|yui] [-v] output input [...]
	-s: Skip JavaScript Validation (JSLint)
	-c rhino|closure|yui:
		rhino: old compressor
		closure: Google Closure Compiler
		yui: Yahoo YUI Compressor (default)
	-v:
		show verbose message, including full JSLint messages.

EOD;
}

/* main process */

$opts = GetOptions();
if (FALSE === $opts || count($argv) < 3) {
	Usage();
	exit(1);
}

$outFile = $argv[1];
$jsFiles = array_slice($argv, 2);
$VerboseMsg = isSet($opts['v']);

$compressor = YUICompress;
if (isSet($opts['c'])) {
	switch ($opts['c']) {
		case 'rhino':
			$compressor = RhinoCompress;
			break;
		case 'closure':
			$compressor = ClosureCompile;
			break;
		case 'yui':
			$compressor = YUICompress;
			break;
		default:
			echo "Error: Invalid Compressor Option.\n";
			Usage();
			exit(1);
	}
}

if (!isSet($opts['s'])) {
	echo "Validating...\n";
	if (ValidateJSFiles($jsFiles, $verbose) > 0) {
		exit(1);
	}
} else {
	echo "Skip JavaScript Validation\n";
}

echo "Compressing...\n";
CompressJSFiles($compressor, $outFile, $jsFiles);
?>
