resource "signalfx_detector" "heartbeat" {
  name = format("%s %s", local.detector_name_prefix, "NTP heartbeat")

  authorized_writer_teams = var.authorized_writer_teams

  max_delay = 900

  program_text = <<-EOF
    from signalfx.detectors.not_reporting import not_reporting
    signal = data('ntp.offset_seconds', filter=${local.not_running_vm_filters} and ${module.filter-tags.filter_custom})${var.heartbeat_aggregation_function}.publish('signal')
    not_reporting.detector(stream=signal, resource_identifier=None, duration='${var.heartbeat_timeframe}').publish('CRIT')
EOF

  rule {
    description           = "has not reported in ${var.heartbeat_timeframe}"
    severity              = "Critical"
    detect_label          = "CRIT"
    disabled              = coalesce(var.heartbeat_disabled, var.detectors_disabled)
    notifications         = coalescelist(lookup(var.heartbeat_notifications, "critical", []), var.notifications.critical)
    runbook_url           = try(coalesce(var.heartbeat_runbook_url, var.runbook_url), "")
    tip                   = var.heartbeat_tip
    parameterized_subject = local.rule_subject_novalue
    parameterized_body    = local.rule_body
  }
}

resource "signalfx_detector" "ntp" {
  name = format("%s %s", local.detector_name_prefix, "NTP offset")

  authorized_writer_teams = var.authorized_writer_teams

  program_text = <<-EOF
        signal = data('ntp.offset_seconds', filter=${module.filter-tags.filter_custom})${var.ntp_aggregation_function}${var.ntp_transformation_function}.publish('signal')
        detect(when(signal > ${var.ntp_threshold_major})).publish('MAJOR')
EOF

  rule {
    description           = "is too high > ${var.ntp_threshold_major}"
    severity              = "Major"
    detect_label          = "MAJOR"
    disabled              = coalesce(var.ntp_disabled, var.detectors_disabled)
    notifications         = coalescelist(lookup(var.ntp_notifications, "major", []), var.notifications.major)
    runbook_url           = try(coalesce(var.ntp_runbook_url, var.runbook_url), "")
    tip                   = var.ntp_tip
    parameterized_subject = local.rule_subject
    parameterized_body    = local.rule_body
  }
}

