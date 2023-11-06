$inactivityDelay = [timespan]::Parse($Env:NO_RECENT_ACTIVITY_DURATION_CLOSE)
$oldIssues = gh issue list --label "$Env:NO_RECENT_ACTIVITY_LABEL" --state open --limit 100 --json number,author | ConvertFrom-Json
foreach($oldIssue in $oldIssues) {
	$lastComment = gh issue view $oldIssue.number --json comments | ConvertFrom-Json | Select-Object -ExpandProperty comments | Where-Object {$_.author.login -eq $oldIssue.author.login} | Select-Object -Last 1
	$labelDate = gh api -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" "/repos/$($Env:ORG_NAME)/$($Env:REPO_NAME)/issues/$($oldIssue.number)/events?per_page=100" | ConvertFrom-Json | Where-Object {$_.event -eq "labeled" -and $_.label.name -eq "$Env:NO_RECENT_ACTIVITY_LABEL"} | Select-Object -Last 1
	$lastCommentDate = [datetime]::Parse($lastComment.created_at)
	$labelDateDate = [datetime]::Parse($labelDate.created_at)
	if ($lastCommentDate -gt $labelDateDate) {
		gh issue edit $oldIssue.number --remove-label "$Env:NO_RECENT_ACTIVITY_LABEL" --remove-label "$Env:NEEDS_AUTHOR_FEEDBACK_LABEL" --add-label "$Env:NEEDS_ATTENTION_LABEL"
	} elseif (($lastCommentDate - $labelDateDate) -le $inactivityDelay) {
		gh issue close $oldIssue.number -r "not planned"
	}
}