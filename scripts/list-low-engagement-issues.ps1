$Env:FEATURE_REQUEST_LABEL = "OpenAPI.Next Proposal"
$Env:REPO = "OAI/OpenAPI-Specification"
$Env:CUTOFF_IN_DAYS = 90
$Env:CUTOFF_TOTAL_REACTIONS = 100

$cutoffInDays = [int]::Parse($Env:CUTOFF_IN_DAYS)
$cutoffTotalReactions = [int]::Parse($Env:CUTOFF_TOTAL_REACTIONS)
$candidatesToClose = gh issue list -R $Env:REPO -l $Env:FEATURE_REQUEST_LABEL --json number,reactionGroups,createdAt --limit 100 --search "created:<$([datetime]::UtcNow.AddDays(-$cutoffInDays).ToString("yyyy-MM-dd"))" | ConvertFrom-Json


$closeToFewReactions = $candidatesToClose | Where-Object { ($_.reactionGroups.users.totalCount | Measure-Object -sum).Sum -le $cutoffTotalReactions }
Write-Host "Closing $($closeToFewReactions.Count) issues with less than $cutoffTotalReactions reactions and created more than $cutoffInDays days ago"
foreach($issue in $closeToFewReactions) {
	Write-Host "Closing issue #$($issue.number) because of low engagement"
}
$evaluateSentiment = $candidatesToClose | Where-Object { ($_.reactionGroups.users.totalCount | Measure-Object -sum).Sum -gt $cutoffTotalReactions }
foreach($issue in $evaluateSentiment) {
	$positiveReactions = 0;
	$negativeReactions = 0;
	foreach($reactionGroup in $issue.reactionGroups) {
		if($reactionGroup.content -eq "THUMBS_UP") {
			$positiveReactions += $reactionGroup.users.totalCount
		} elseif($reactionGroup.content -eq "THUMBS_DOWN") {
			$negativeReactions += $reactionGroup.users.totalCount
		} elseif ($reactionGroup.content -eq "LAUGH") {
			# noop - it's not clear what people meant by this
		} elseif ($reactionGroup.content -eq "CONFUSED") {
			$negativeReactions += $reactionGroup.users.totalCount
		} elseif ($reactionGroup.content -eq "HOORAY") {
			$positiveReactions += $reactionGroup.users.totalCount
		} elseif ($reactionGroup.content -eq "HEART") {
			$positiveReactions += $reactionGroup.users.totalCount
		} elseif ($reactionGroup.content -eq "ROCKET") {
			$positiveReactions += $reactionGroup.users.totalCount
		} elseif ($reactionGroup.content -eq "EYES") {
			# noop - it's not clear what people meant by this
		}
	}
	if ($negativeReactions -eq 0) {
		$negativeReactions = 1
	}
	$reactionRatio = $positiveReactions / $negativeReactions
	if($reactionRatio -lt 2) {
		Write-Host "Closing issue #$($issue.number) with positive reaction ratio of $reactionRatio"
	} else {
		Write-Host "Keeping issue #$($issue.number) with positive reaction ratio of $reactionRatio"
	}
}