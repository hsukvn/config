#!/usr/bin/php
<?php

$progname = array_shift($argv);
$action = array_shift($argv);

if (!$action) {
	return usage();
}

require("syntax.php");

BugDb::connect();

$config = array(
	"project" => array(
		"Mail Server" => true,
		"Glacier Backup" => true,
		"Time Backup" => true,
		"Syslog Server" => true,
		"VPN Server" => true,
		"DSM" => true,
	),
	"filter" => array(
		"bat-new" => array(
			"status" => BugStatus::get_by_names("@rd"),
			"assign_to" => BugUser::get_by_names("@bat"),
			"last_week" => true
		),
		"bat-last" => array(
			"fixed_by" => BugUser::get_by_names("@bat"),
			"last_week" => true
		),
		"bat-act" => array(
			"label" => "MFBR 2013Q1 beta",
			"status" => BugStatus::get_by_names("@rd"),
			"assign_to" => BugUser::get_by_names("@bat"),
		),
		"bat-fixed" => array(
			"label" => "MFBR 2013Q1 beta",
			"fixed_by" => BugUser::get_by_names("@bat1"),
		),
		"dsm5.0" => array(
			"status" => BugStatus::get_by_names("@rd"),
			"label" => "MFBR 2014Q1 Beta",
			"assign_to" => BugUser::get_by_names("@bat"),
		),
	),
	"user" => "thlu",
);

switch ($action) {
case "T": case "table":
	return enum_all_tables();
case "q": case "query":
	return action_query($argv);
case "f": case "filter":
	return action_filters($argv);
case "b": case "bug":
	return action_bugs($argv);
case "u": case "user":
	return action_user($argv);
case "s": case "sql":
	return action_sql($argv);
case "status":
	return action_status($argv);
}
function usage() {
	global $progname;
	print("Usage:  $progname [action] [options]
Action
  T|table			dump all tables in bugdb
  f|filter [user]		dump filters by user
  f|filter [id] [sql]		set SQL of filter by filter id
  b|bug	[proj] [bug id]		dump all bugs of proj or single bug
  u|user [name]			get info of user by name
  s|sql [condition]		dump sql by condition
  q|query ...			query
");
	return;
}

function dump_bug_console($row, $proj_id) {
	$user = BugUser::get($row["assign_to"]);
	$st = BugStatus::get($row["status"]);

	$url = sprintf("https://bug.synology.com/report/report_show.php?project_id=%d&report_id=%d",
		$proj_id,
		$row["report_id"]
	);
	printf("%6d %15s %15s %s\n",
		$row["report_id"],
		$st,
		$user,
		$row["summary"]);
}
function dump_bug_raw($row, $proj_id) {
	print_r($row);
}

function enum_all_tables() {
	print_r(BugDb::$db->enum_all_tables());
}

function action_query($argv) {
	global $config;
	if (1 == count($argv)) {
		$res = BugDb::$db->query($argv[0]);

		while ($row = pg_fetch_assoc($res)) {
			print_r($row);
		}
	}
}

function get_bug($proj_name, $bug_id) {
	$p = BugProject::get_by_name($proj_name);
	$p->each('dump_bug_raw', array("report_id" => array($bug_id)));
}
function enum_bugs($proj_names, $filter = null) {
	if (null !== $filter && isset($filter["label"])) {
		$label_str = " - ".$filter["label"];
	} else {
		$label_str = "";
	}

	if (is_array($proj_names)) {
		foreach ($proj_names as $proj_name => $bug_ids) {
			if (is_array($bug_ids)) {
				if (null === $filter) {
					$filter = array("report_id" => $bug_ids);
				} else {
					$filter["report_id"] = $bug_ids;
				}
			}
			enum_bugs($proj_name, $filter);
		}
		return true;
	}

	$p = BugProject::get_by_name($proj_names);
	if (null === $p) {
		echo("no such project: $proj_names\n");
		return false;
	}

	printf("===== %s%s =====\n", $p->name, $label_str);
	return $p->each('dump_bug_console', $filter);
}
function action_bugs($argv) {
	global $config;
	if (0 == count($argv)) {
		echo("active bugs\n");
		enum_bugs($config["project"], $config["filter"]["bat-act"]);
		return true;
	} else if (1 == count($argv)) {
		if (isset($config["filter"][$argv[0]])) {
			return enum_bugs($config["project"], $config["filter"][$argv[0]]);
		} else {
			printf("no such filter: %s\n", $argv[0]);
			return false;
		}
	} else if (2 == count($argv)) {
		if (isset($config["filter"][$argv[1]])) {
			return enum_bugs($argv[0], $config["filter"][$argv[0]]);
		} else {
			return get_bug($argv[0], $argv[1]);
		}
	} else {
		return usage();
	}
}

function enum_filters($user_name) {
	$res = BugDb::$db->query("
		SELECT f.filter_id,f.filter_name,f.real_condition,f.text_condition
		FROM filter_table f
		LEFT OUTER JOIN user_table u ON u.user_id = f.user_id
		WHERE u.username = $1", $user_name);

	printf("num of row: %d\n", pg_num_rows($res));

	while ($row = pg_fetch_assoc($res)) {
		print_r($row);
		print("\n");
	}
}
function set_filter($filter_id, $attrs) {
	return pg_update(BugDb::$db->_conn, 'filter_table', $attrs, array("filter_id" => $filter_id));
}
function action_filters($argv) {
	global $config;

	if (0 == count($argv)) {
		return enum_filters($config["user"]);
	} else if (1 == count($argv)) {
		return enum_filters($argv[0]);
	} else if (2 == count($argv)) {
		return set_filter($argv[0], array("filter_name" => $argv[1]));
	} else if (3 == count($argv) && "set" === $argv[0]) {
		if (isset($config["filter"][$argv[2]])) {
			$sql = BugDb::sql_filter($config["filter"][$argv[2]]);
		} else {
			printf("no such filter: %s", $argv[2]);
			return false;
		}
		$values = array(
			"filter_name" => $argv[2],
			"text_condition" => $argv[2],
			"real_condition" => $sql,
		);
		return set_filter($argv[1], $values);
	} else if (4 == count($argv)) {
		return set_filter($argv[0], array("filter_name" => $argv[1],
		       	"real_condition" => $argv[2], "text_condition" => $argv[3]));
	} else {
		return usage();
	}
}

function action_user($argv) {
	if (0 == count($argv)) {
		return usage();
	} else if (1 == count($argv)) {
		$u = BugUser::get_by_name($argv[0]);
		if (null === $u) {
			$u = BugUser::get($argv[0]);
		}
		if (null === $u) {
			printf("no such user: %s", $argv[0]);
		}
		print_r($u);
		print("\n");
	} else {
		return usage();
	}
}

function action_status($argv) {
	if (0 == count($argv)) {
		$sql = "SELECT * FROM ".BugStatus::TABLE." WHERE status_type = 'active'";
		$res = BugDb::$db->query($sql);

		while ($row = pg_fetch_array($res)) {
			print_r($row);
		}
		return true;
	} else {
		return usage();
	}
}

function action_sql($argv) {
	global $config;

	$op = array_shift($argv);

	if (isset($config["filter"][$op])) {
		$sql = BugDb::sql_filter($config["filter"][$op]);
	} else if (isset(BugDb::$filter_map[$op])) {
		$condition = array();
		array_unshift($argv, $op);

		for ($i = 0 ; $i < count($argv) ; $i+=2) {
			$condition[$argv[$i]] = $argv[$i+1];
		}

		$sql = BugDb::sql_filter2($condition);
	} else {
		printf("undefined operation, please set by filter name or condition\n");

		printf("\n  filter names: ");
		foreach ($config["filter"] as $key => $value) {
			printf("%s, ", $key);
		}

		printf("\n  condition keys: ");
		foreach (BugDb::$filter_map as $key => $value) {
			printf("%s, ", $key);
		}
		printf("\n");

		return ;
	}

	printf($sql."\n");
}

?>
