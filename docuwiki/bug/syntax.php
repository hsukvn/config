<?php
/**
 * @license    GPL 2 (http://www.gnu.org/licenses/gpl.html)
 * @author     thlu <thlu@synology.com>
 *
 * example:
 *
 * show all bugs assigned to bat team and labeled with "MFBR 2013Q3 Release" and
 *  in project: dsm, mailserver, mailstation, glacier, hidrive, vpn, syslog,
 *  timebkp
 * ~~bug:status=@rd&assign_to=@bat&label=MFBR 2013Q3 Release&dsm&mailserver&mailstation&glacier&hidrive&vpn&syslog&timebkp~~
 *
 * show all bugs with priority higher than 4
 * ~~bug:status=@rd&assign_to=@bat&priority=4&dsm&mailserver&mailstation&glacier&hidrive&vpn&syslog&timebkp~~
 *
 * show MailStation #81
 * ~~bug:format=row&MailStation=81~~
 */

function array_append(&$a1, $a2) {
	if (is_array($a2)) {
		foreach ($a2 as $i) {
			$a1[] = $i;
		}
	} else {
		$a1[] = $a2;
	}
}

class BugDb {
	//const HOST = "bug.synology.com";
	const HOST = "bugdb.synology.com";
	const DBNAME = "bugdb";

	static public $db = null;
	static function connect($user = "syno", $password = "syno") {
		BugDb::$db = new BugDb($user, $password);
	}

	var $_conn = null;

	function __construct($user, $password) {
		$this->_conn = pg_connect(sprintf(
			"host=%s dbname=%s user=%s password=%s",
			BugDb::HOST, BugDb::DBNAME, $user, $password));
	}
	function close() {
		pg_close($this->_conn);
		$this->_conn = null;
		return ;
	}

	function query() {
		$args = func_get_args();
		$sql_template = array_shift($args);

		$res = pg_query_params($this->_conn, $sql_template, $args) or
			die("query failed: [$sql_template(".join(',',$args).")]\n");
		return $res;
	}

	function enum_all_tables() {
		$res = $this->query("SELECT table_name FROM information_schema.tables
			WHERE table_schema = 'public' and table_type = 'BASE TABLE'");

		$table = array();
		while ($row = pg_fetch_assoc($res)) {
			if ("proj" != substr($row["table_name"], 0, 4)) {
				$table[] = $row["table_name"];
			}
		}
		return $table;
	}

	public static $filter_map = array(
		"assign_to" => "BugDb::sql_or_user",
		"fixed_by" => "BugDb::sql_or_user",
		"status" => "BugDb::sql_or_status",
		"report_id" => "BugDb::sql_or_bug_id",
		"type" => "BugDb::sql_bug_type",
	);

	static function sql_or_user($key, $value, $prefix = "") {
		$c = array();
		if (!is_array($value)) {
			$value = explode(",", $value);
		}

		foreach ($value as $i) {
			if ($i instanceof BugUser) {
				$id = pg_escape_string($i->id);
			} else {
				$user = BugUser::get_by_name($i);
				$id = pg_escape_string($user ? $user->id : $i);
			}
			$c[] = sprintf("$prefix$key=%s", $id);
		}
		if (0 < count($c)) {
			return join(" OR ", $c);
		} else {
			return null;
		}
	}
	static function sql_or_status($key, $value, $prefix = "") {
		$c = array();
		if (!is_array($value)) {
			$value = explode(",", $value);
		}
		foreach ($value as $i) {
			if ($i instanceof BugStatus) {
				$id = pg_escape_string($i->id);
			} else {
				$st = BugStatus::get_by_name($i);
				$id = pg_escape_string($st ? $st->id : $i);
			}
			$c[] = sprintf("$prefix$key=%s", $id);
		}
		if (0 < count($c)) {
			return join(" OR ", $c);
		} else {
			return null;
		}
	}
	static function sql_or_bug_id($key, $value, $prefix = "") {
		$c = array();
		if (!is_array($value)) {
			$value = explode(",", $value);
		}

		foreach ($value as $item) {
			$c[] = sprintf("$prefix$key=%d", $item);
		}
		if (0 < count($c)) {
			return join(" OR ", $c);
		} else {
			return null;
		}
	}
	static function sql_bug_type($key, $value, $prefix = "") {
		$v = 1;
		switch ($value) {
			case "release":
				$v = 5;
				break;
			case "bug":
				$v = 1;
				break;
			case "suggestion":
				$v = 6;
				break;
			case "feature":
				$v = 2;
				break;
		}
		return sprintf($prefix."type=%d", $v);
	}

	static function sql_filter2($filter, $table_name = null, $default = "TRUE") {
		$prefix = $table_name ? "$table_name." : "";
		$condition = array();

		foreach ($filter as $k => $v) {
			if (isset(BugDb::$filter_map[$k])) {
				$c = call_user_func(BugDb::$filter_map[$k], $k, $v, $prefix);
				if ($c) {
					$condition[] = $c;
				}
			} else {
				printf("invalid key: %s\n", $k);
			}
		}

		if (0 === count($condition)) {
			return " $default";
		} else {
			return " ((".join(")AND(", $condition)."))";
		}
	}

	static function sql_filter($filter, $table_name = null, $default = "TRUE") {
		if ($table_name) {
			$prefix = "$table_name.";
		} else {
			$prefix = "";
		}
		$condition = array();
		foreach ($filter as $k => $v) {
			$c = array();
			if ($k === "assign_to" || $k === "fixed_by" || $k === "status" || $k === 'owner') {
				foreach ($v as $i) {
					if ($i instanceof BugUser || $i instanceof BugStatus) {
						$id = pg_escape_string($i->id);
					} else {
						$id = pg_escape_string($i);
					}
					$c[] = $id;
				}
				if (0 < count($c)) {
					if ($k !== 'owner') {
						$condition[] = sprintf("$prefix$k IN (%s)", join(",", $c));
					} else {
						$condition[] = sprintf("(".
							$prefix."assign_to IN (%s) OR ".
							$prefix."fixed_by IN (%s))",
							join(",", $c),
							join(",", $c));
					}
				}
			} elseif ($k === "report_id") {
				foreach ($v as $i) {
					$c[] = $i;
				}
				if (0 < count($c)) {
					$condition[] = sprintf("$prefix$k IN (%s)", join(",", $c));
				}
			} elseif ($k === "label") {
				continue;
			} elseif ($k === "last_week") {
				$condition[] = "(NOW() - $prefix"."created_date < INTERVAL '7 day')";
			} elseif ($k === "priority") {
				$condition[] = "$prefix"."priority >= $v";
			} elseif ($k === "type") {
				$condition[] = BugDb::sql_bug_type($k, $v, $prefix);
			}
		}

		if (0 === count($condition)) {
			return " $default";
		} else {
			return " ((".join(")AND(", $condition)."))";
		}
	}
}
class BugLabel {
	public $id = null;
	public $name = null;
	public $project_id = null;
	public $color = null;

	function __construct($row) {
		$this->id = $row["label_id"];
		$this->name = $row["label_name"];
		$this->project_id = $row["project_id"];
		$this->color = $row["color"];
	}

	function each($func, $filter = null) {
		$sql = sprintf("SELECT * FROM proj%d_report_table p
			LEFT OUTER JOIN label_mapping_table l
			ON p.report_id = l.report_id
			WHERE l.label_id=$1", $this->project_id);

		if ($filter) {
			$sql .= " AND".BugDb::sql_filter($filter, "p");
		}

		$sql .= " ORDER BY p.report_id DESC";

		$count = 0;
		$res = BugDb::$db->query($sql, $this->id);

		while ($row = pg_fetch_assoc($res)) {
			if (false === $func($row, $this->project_id)) {
				break;
			}
			$count += 1;
		}

		return $count;
	}

	function is_labeled($report_id) {
		$sql = "SELECT count(*) FROM label_mapping_table
			WHERE report_id = $1 AND label_id = $2";
		$res = BugDb::$db->query($sql, $report_id, $this->id);

		$row = pg_fetch_result($res, 0, 0);
		return $row > 0;
	}
}
class BugProject {
	public $name = null;
	public $id = null;
	public $labels = null;

	const TABLE = "project_table";

	static function _query_project($id, $name) {
		$sql = "SELECT * FROM ".BugProject::TABLE;

		if (null !== $id) {
			$sql .= " WHERE project_id = $1";
			$res = BugDb::$db->query($sql, $id);
		} else {
			$sql .= " WHERE project_name = $1";
			$res = BugDb::$db->query($sql, $name);
		}

		if (pg_num_rows($res) !== 1) {
			return null;
		}

		$record = pg_fetch_assoc($res);

		return new BugProject($record);
	}

	function __construct($db_record) {
		$this->id = $db_record["project_id"];
		$this->name = $db_record["project_name"];
		$this->labels = array();
		$this->_query_labels();
	}

	function _query_labels() {
		$sql = "SELECT * FROM label_table WHERE project_id = $1";
		$res = BugDb::$db->query($sql, $this->id);

		while ($row = pg_fetch_assoc($res)) {
			$l = new BugLabel($row);
			$this->labels[] = $l;
		}
	}

	static function get($project_id) {
		return BugProject::_query_project($project_id, null);
	}
	static function get_by_name($project_name) {
		switch ($project_name) {
		case "dsm": $project_name = "DSM"; break;
		case "dr3": $project_name = "iUSB & Data Replicator"; break;
		case "mailserver": $project_name = "Mail Server"; break;
		case "mailstation": $project_name = "MailStation"; break;
		case "glacier": $project_name = "Glacier Backup"; break;
		case "hidrive": $project_name = "HiDrive Backup"; break;
		case "vpn": $project_name = "VPN Server"; break;
		case "syslog": $project_name = "Syslog Server"; break;
		case "timebkp": $project_name = "Time Backup"; break;
		}
		return BugProject::_query_project(null, $project_name);
	}

	function get_label($label_id) {
		foreach ($this->labels as $l) {
			if ($label_id === $l->id) {
				return $l;
			}
		}
		return null;
	}
	function get_label_by_name($label_name) {
		foreach ($this->labels as $l) {
			if (0 == strcasecmp($label_name, $l->name)) {
				return $l;
			}
		}
		return null;
	}

	function each($func, $filter = null) {
		if (null !== $filter && isset($filter["label"])) {
			$l = $this->get_label_by_name($filter["label"]);
			if (null === $l) {
				die("no such label [".$filter["label"]."] in ".$this->name);
			}

			return $l ? $l->each($func, $filter) : false;
		}

		$sql = sprintf("SELECT * FROM proj%d_report_table", $this->id);

		if ($filter) {
			$sql .= " WHERE".BugDb::sql_filter($filter);
		}

		$sql .= " ORDER BY report_id DESC";

		$count = 0;
		$res = BugDb::$db->query($sql);

		while ($row = pg_fetch_assoc($res)) {
			if (false === $func($row, $this->id)) {
				break;
			}
			$count += 1;
		}

		return $count;
	}

	function each_not_labeled($func, $filter = null) {
		$sql = sprintf("SELECT *,p.report_id FROM proj%d_report_table p
			LEFT JOIN (
				SELECT l1.label_id,l1.report_id FROM label_mapping_table l1
				INNER JOIN label_table l2
				ON l1.label_id=l2.label_id WHERE l2.project_id=%d
			) l
			ON p.report_id = l.report_id
			WHERE ", $this->id, $this->id);

		if ($filter) {
			$sql .= BugDb::sql_filter($filter, "p") . " AND l.label_id is NULL";
		} else {
			$sql .= " l.label_id is NULL";
		}

		$sql .= " ORDER BY p.report_id DESC";

		$count = 0;
		$res = BugDb::$db->query($sql);

		$existed = array();

		while ($row = pg_fetch_assoc($res)) {
			if (array_key_exists($row["report_id"], $existed)) {
				continue;
			}
			$existed[$row["report_id"]] = true;
			if (false === $func($row, $this->id)) {
				break;
			}
			$count += 1;
		}

		return $count;
	}
}
class BugUser {
	public $id = null;
	public $name = null;

	static $_mapping_id = null;
	static $_mapping_name = null;

	const TABLE = "user_table";

	static function _query_user($user_id, $user_name) {
		$sql = "SELECT * FROM ".BugUser::TABLE;

		if (null !== $user_id) {
			$sql .= " WHERE user_id=$1";
			$res = BugDb::$db->query($sql, $user_id);
		} else {
			$sql .= " WHERE username=$1";
			$res = BugDb::$db->query($sql, $user_name);
		}

		if (pg_num_rows($res) !== 1) {
			return null;
		}

		$record = pg_fetch_array($res);

		return new BugUser($record);
	}

	function __construct($db_record) {
		$this->id = $db_record["user_id"];
		$this->name = $db_record["username"];
	}
	function __toString() {
		return $this->name;
	}

	static function _init_cache() {
		if (null === BugUser::$_mapping_id) {
			BugUser::$_mapping_id = array();
		}
		if (null === BugUser::$_mapping_name) {
			BugUser::$_mapping_name = array();
		}
	}
	static function _get_cached_user($user_id, $user_name) {
		BugUser::_init_cache();

		try {
			if (null !== $user_id) {
				$u = @BugUser::$_mapping_id[$user_id];
			} else {
				$u = @BugUser::$_mapping_name[$user_name];
			}
			return $u;
		} catch (Exception $e) {
			return null;
		}
	}
	static function _set_cached_user($user) {
		BugUser::_init_cache();

		BugUser::$_mapping_id[$user->id] = $user;
		BugUser::$_mapping_name[$user->name] = $user;
	}

	static function get($user_id) {
		if (-1 == $user_id) {
			return null;
		}
		$u = BugUser::_get_cached_user($user_id, null);

		if (null === $u) {
			$u = BugUser::_query_user($user_id, null);
		}

		if (null === $u) {
			// error handling
			return null;
		} else {
			BugUser::_set_cached_user($u);
			return $u;
		}
	}
	static function get_team_by_abbr($abbr_name) {
		$abbr_name = strtolower($abbr_name);
		switch ($abbr_name) {
			case "bat": return array("Business Application");
			case "nit": return array("Network Infrastructure");
			case "sit": return array("System Integration");
			case "dit": return array("Developing Infrastructure");
			case "bpt": return array("Business Platform");
			case "cpt": return array("Consumer Platform");
			case "stt": return array("Storage Technology");
			case "cat": return array("Cloud Application");
			case "mot": return array("Mobile Application");
			case "mat": return array("Multimedia Application");
			case "wat": return array("Web Application");
			case "sur": return array("Surveillance");
			case "sdg4": return array("Business Application",
				"Network Infrastructure", "System Integration",
				"Developing Infrastructure");
		}
		return array($abbr_name);
	}
	static function get_members($team_name) {
		$members = array();
		$team_name = BugUser::get_team_by_abbr($team_name);
		$userinfo = json_decode(file_get_contents(__DIR__. "/config/contact.json"), true);

		foreach ($userinfo["data"] as $userjson) {
			$tname = $userjson["department"];

			if (in_array($tname, $team_name)) {
				$members[] = BugUser::get_by_name($userjson["account"]);
			}
		}
		return $members;
	}
	static function get_by_name($user_name) {
		if ('@' === substr($user_name, 0, 1)) {
			return BugUser::get_members(substr($user_name, 1));
		}
		$u = BugUser::_get_cached_user(null, $user_name);

		if (null === $u) {
			$u = BugUser::_query_user(null, $user_name);
		}

		if (null === $u) {
			// error handling
			return null;
		} else {
			BugUser::_set_cached_user($u);
			return $u;
		}
	}
	static function get_by_names() {
		$users = array();
		foreach (func_get_args() as $uname) {
			if (is_array($uname)) {
				foreach ($uname as $i) {
					array_append($users, BugUser::get_by_name($i));
				}
			} else {
				array_append($users, BugUser::get_by_name($uname));
			}
		}
		return $users;
	}
}
class BugStatus {
	public $id = null;
	public $name = null;
	public $color = null;
	public $type = null;

	static $_mapping_id = null;
	static $_mapping_name = null;

	const TABLE = "status_table";

	static function _init_status_mapping() {
		if (null !== BugStatus::$_mapping_id) {
			return;
		}

		$sql = "SELECT * FROM ".BugStatus::TABLE;
		$res = BugDb::$db->query($sql);

		BugStatus::$_mapping_id = array();
		BugStatus::$_mapping_name = array();

		while ($row = pg_fetch_array($res)) {
			$s = new BugStatus($row);

			BugStatus::$_mapping_id[$s->id] = $s;
			BugStatus::$_mapping_name[$s->name] = $s;
		}
	}

	function __construct($db_record) {
		$this->id = $db_record["status_id"];
		$this->name = $db_record["status_name"];
		$this->color = $db_record["status_color"];
		$this->type = $db_record["status_type"];
	}

	function __toString() {
		return $this->name;
	}

	static function get($status_id) {
		BugStatus::_init_status_mapping();
		return BugStatus::$_mapping_id[$status_id];
	}
	static function get_by_name($status_name) {
		BugStatus::_init_status_mapping();

		$sts = array();
		if ("@rd" === $status_name) {
			foreach (array("In process", "New", "Re-do", "Under investigation") as $i) {
				array_append($sts, BugStatus::get_by_name($i));
			}
			return $sts;
		} else if ("@qc" === $status_name) {
			foreach (array("Created for test", "Fixed", "Re-test", "Re-verify", "Stressing") as $i) {
				array_append($sts, BugStatus::get_by_name($i));
			}
			return $sts;
		} else {
			return BugStatus::$_mapping_name[$status_name];
		}
	}
	static function get_by_names() {
		$sts = array();
		foreach (func_get_args() as $st_name) {
			if (is_array($st_name)) {
				foreach ($st_name as $i) {
					array_append($sts, BugStatus::get_by_name($i));
				}
			} else {
				array_append($sts, BugStatus::get_by_name($st_name));
			}
		}
		return $sts;
	}

	static function dump_all() {
		BugStatus::_init_status_mapping();

		foreach (BugStatus::$_mapping_id as $id => $s) {
			printf("%s\t%s\t%s\t%s\n", $s->id, $s, $s->color, $s->type);
		}
	}
}

// must be run within Dokuwiki
if(!defined('DOKU_INC')) return;

BugDb::connect();

function get_priority_str($p) {
	switch ($p) {
	case 5: return "urgent";
	case 4: return "high";
	case 3: return "normal";
	case 2: return "low";
	case 1:
	case 0:
	default:
	       	return "";
	}
}

$bug_htmls = "";
$bug_project = "";

function dump_start_by_project()
{
	return '<colgroup>
	       		<col style="width: 8%;">
			<col style="width: 8%;">
			<col style="width: 6%;">
			<col style="width: 10%;">
			<col>
		</colgroup>';
}
function dump_title_by_project($projname, $comment = null, $label = null)
{
	return sprintf("<tr><th colspan=5>%s%s%s</th></tr>",
		$projname,
		$label ? "($label)" : "",
		$comment ? " - $comment" : "");
}
function dump_bug_by_project($row, $proj_id)
{
	global $bug_htmls;

	$user = BugUser::get($row["assign_to"]);
	$st = BugStatus::get($row["status"]);

	$url = sprintf("https://bug.synology.com/report/report_show.php?project_id=%d&report_id=%d",
		$proj_id,
		$row["report_id"]
	);
	$bug_htmls .= sprintf("<tr>
		<td>%d</td>
		<td><font color=%s>%s</font></td>
		<td>%s</td>
		<td>%s</td>
		<td><a href=\"%s\" target=_blank>%s</a></td>
		</tr>\n",
		$row["report_id"],
		$st->color,
		$st,
		get_priority_str($row["priority"]),
		$user,
		$url,
		$row["summary"]);
}
function dump_none_by_project()
{
	return "<tr><td colspan=5 align=center>no records</td></tr>";
}

function dump_start_row()
{
	return '<colgroup>
	       		<col style="width: 15%;">
			<col style="width: 7%;">
			<col style="width: 7%;">
			<col style="width: 9%;">
			<col style="width: 10%;">
			<col>
		</colgroup>
		<tr>
			<th>project</th>
			<th>id</th>
			<th>version</th>
			<th>status</th>
			<th>assign</th>
			<th>summary</th>
		</tr>
		';
}
function dump_title_row($projname, $comment = null, $label = null)
{
	return "";
}
function dump_bug_row($row, $proj_id)
{
	global $bug_htmls;
	global $bug_project;

	$user = BugUser::get($row["assign_to"]);
	$st = BugStatus::get($row["status"]);

	$url = sprintf("https://bug.synology.com/report/report_show.php?project_id=%d&report_id=%d",
		$proj_id,
		$row["report_id"]
	);
	$bug_htmls .= sprintf("<tr>
		<th>%s</td>
		<td>%d</td>
		<td>%s</td>
		<td><font color=%s>%s</font></td>
		<td>%s</td>
		<td><a href=\"%s\" target=_blank>%s</a></td>
		</tr>\n",
		$bug_project,
		$row["report_id"],
		$row["fixed_in_version"],
		$st->color,
		$st,
		$user,
		$url,
		$row["summary"]);
}
function dump_none_row()
{
	return "";
}

class syntax_plugin_bugs extends DokuWiki_Syntax_Plugin
{
	function getInfo(){
		return array(
			'author' => 'thlu',
			'email'  => 'thlu@synology.com',
			'date'   => '2012-12-21',
			'name'   => 'Bug Tracker Plugin',
			'desc'   => 'Displays Bug information From bug tracker',
			'url'    => 'http://dokuwiki.org/plugin:info',
		);
	}

	function getType(){
		return 'substition';
	}
	function getPType(){
		return 'block';
	}
	function getSort(){
		return 156;
	}

	function connectTo($mode) {
		$this->Lexer->addSpecialPattern("~~bug:[_a-z\ A-Z0-9\%\:@\.,\\\/\*\-\+\(\)\&\|#><!=;]*~~",$mode,'plugin_bugs');
	}
	function handle($match, $state, $pos, &$handler){
		$match = substr($match,6,-2); //strip ~~INFO: from start and ~~ from end
		return explode('&', $match);
	}
	function render($format, &$renderer, $data) {
		global $bug_htmls;
		global $bug_project;

		if($format !== 'xhtml'){
			return false;
		}

		$doc = "";
		$label = null;
		$filter = array();
		$projs = array();
		$format = "by_project";

		foreach ($data as $i) {
			$a = explode('=', $i, 2);

			if (1 === count($a)) {
				$key = $a[0];
				$value = null;
			} else if (2 === count($a)) {
				$key = $a[0];
				$value = $a[1];
			}

			if ("label" === $key && null !== $value) {
				$label = $value;
			} elseif ("format" === $key && null !== $value) {
				$format = $value;
			} elseif (null != $value && "assign_to" === $key) {
				$filter[$key] = BugUser::get_by_names(explode(',', $value));
			} elseif (null != $value && "status" === $key) {
				$filter[$key] = BugStatus::get_by_names(explode(',', $value));
			} elseif (null != $value && "priority" === $key) {
				$filter[$key] = $value;
			} else {
				// project name and report_ids
				$a = explode('#', $key, 2);
				if (1 === count($a)) {
					$key = $a[0];
					$comment = "";
				} else if (2 === count($a)) {
					$key = $a[0];
					$comment = $a[1];
				}
				$projs[] = $key;
				$proj_comment[$key] = $comment;
				$report_id[$key] = $value;
			}
		}

		$doc .= '<div class=table><table class="inline" style="width:95%;">';
		$doc .= call_user_func("dump_start_$format");
		foreach ($projs as $proj_name) {
			$p = BugProject::get_by_name($proj_name);

			if (null == $p) {
				$doc .= call_user_func("dump_title_$format", $proj_name, "no such project");
				continue;
			}

			if ($report_id[$proj_name]) {
				$filter["report_id"] = explode(',', $report_id[$proj_name]);
			} else {
				unset($filter["report_id"]);
			}

			$comment = $proj_comment[$proj_name];

			$bug_htmls = "";
			$bug_project = $p->name;
			if ($label) {
				$l = $p->get_label_by_name($label);

				if (null === $l) {
					$doc .= call_user_func("dump_title_$format", $p->name, $comment, "no such label");
					continue;
				}
				$doc .= call_user_func("dump_title_$format", $p->name, $comment, $l->name);
				$l->each("dump_bug_$format", $filter);
			} else {
				$doc .= call_user_func("dump_title_$format", $p->name, $comment);
				$p->each("dump_bug_$format", $filter);
			}

			if (!$bug_htmls) {
				$doc .= call_user_func("dump_none_$format");
			} else {
				$doc .= $bug_htmls;
				/*
				$doc .= "<tr>
					<th>id</th><th>status</th> <th>assign to</th><th>summary</th>
					</tr>
					$bug_htmls";
				*/
			}
		}
		$doc .= '</table></div>'."\n";

		$renderer->doc .= $doc;

		return true;
	}

	function _addToTOC($text, $level, &$renderer){
		global $conf;

		if (($level >= $conf['toptoclevel']) && ($level <= $conf['maxtoclevel'])){
			$hid  = $renderer->_headerToLink($text, 'true');
			$renderer->toc[] = array(
				'hid'   => $hid,
				'title' => $text,
				'type'  => 'ul',
				'level' => $level - $conf['toptoclevel'] + 1
			);
		}
		return $hid;
	}
}
