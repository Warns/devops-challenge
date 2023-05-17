function edit_time(tag, timestamp, record)
    new_record = record
    new_record["@timestamp"] = os.date("%Y-%m-%dT%H:%M:%S")
    return 1, timestamp, new_record
end
