# Some global variables that get used around the place for limiting the scope of the data being worked with
start <- ymd('2018-10-29', tz="Australia/Brisbane")
end <- ymd("2018-11-05", tz="Australia/Brisbane")
period <- interval(start, end)
prefix_length <- 10
group_length <- 3

source(here::here('plots.R'))

# Import a json dump file
# This isn't really used anymore.
import_dump <- function(filename) {
  filename %>% 
    file %>% 
    stream_in(flatten=T) %>% 
    as_tibble() %>%
    mutate(request.timestamp_start = as_datetime(request.timestamp_start/1000, tz="Australia/Brisbane"), request.timestamp_end = as_datetime(request.timestamp_end/1000, tz="Australia/Brisbane"))
}

# Make a date time object with the Brisbane timezone.
bne_date_time <- function(data) {
  as_datetime(as.numeric(data)/1000, tz="Australia/Brisbane")
}

# Read the log files and parse for TLS passthrough entries.
read_log <- function(file) {
  read_fwf(here::here('data','proxy',file), fwf_widths(c(30, NA))) %>% 
    filter(str_detect(X2, "TLS passthrough")) %>% 
    bind_cols(list(str_extract(.$X2, "(?<=')[^']*"))) %>% 
    mutate(timestamp = with_tz(X1, "Australia/Brisbane")) %>%
    select(timestamp, host=V1)
}

# Return passthrough_logs and create it if it doesn't exist
get_passthrough_logs <- function() {
  if (!exists("passthrough_logs")) {
    passthrough_logs <<- bind_rows("laptop" = read_log('proxy-laptop.log'), "mobile" = read_log('proxy-mobile.log'), .id="device") %>%
      filter(timestamp %within% period)
  }
  passthrough_logs
}

# Return requests_common (and create it if it doesn't exist)
get_requests_common <- function() {
  if( !exists("requests_common") ) {
    requests_common <<- requests_narrow %>%
      filter(field == "request.host" | field == "request.timestamp_start" | field== 'device') %>%
      spread(field, value) %>%
      mutate(host=request.host, timestamp = bne_date_time(request.timestamp_start)) %>%
      filter(timestamp %within% period) %>%
      select(id, device, timestamp, host ) %>%
      bind_rows(get_passthrough_logs()) %>%
      left_join(get_domain_data(), by=c('host'='host'))
  }
  requests_common
}

get_requests_data <- function() {
  if (!exists("requests_data")) {
    ids <- requests_narrow %>% 
      filter(field=="request.timestamp_start") %>% 
      mutate(value=bne_date_time(value)) %>% 
      filter(value %within% period)
    requests_data <<- requests_narrow %>% filter(id %in% ids$id)
  }
  requests_data
}

# Generate a list of all the domains seen in the data across some passthrough, request host and referers.
get_domain_data <- function() {
  
  if (!exists("domain_data")) {
    domain_data <<- get_request_data() %>% 
      
      # Select just the hosts
      filter(field == 'request.host') %>% 
      distinct(value) %>% 
      
      # Add in all the referer domains
      bind_rows(
        requests_narrow %>% 
          filter(field == 'request.headers.referer') %>% 
          distinct(value) %>% 
          bind_cols(urltools::url_parse(.$value)) %>% 
          select(value=domain) %>%
          distinct(value)
      ) %>%
      
      # Add in passthrough domains
      bind_rows(
        passthrough_logs %>%
          distinct(host) %>%
          select(value=host) %>%
          distinct(value)
      ) %>%
      
      # Distinct
      distinct(value) %>%
      
      # Get the 'top' domain
      bind_cols(tldextract(.$value)) %>% 
      mutate(top_host=if_else(is.na(domain),host,paste(domain,tld,sep="."))) %>%
      distinct(host, .keep_all=T) %>%
      select(host, domain=top_host)
  }
  
  domain_data
}

get_domain_key_data <- function() {
  if (! exists("domain_key_data")) {
    query_params <- get_requests_common() %>% 
      add_field('request.path') %>%
      bind_cols(urltools::url_parse(.$request.path)) %>% 
      select(id, domain, parameter) %>%
      filter(!is.na(parameter)) %>% 
      separate_rows(parameter, sep="&") %>% 
      separate(parameter, c('key','value'), sep="=", fill="right", extra="merge") %>%
      mutate(value=url_decode(value))
    
    cookies <- get_requests_common() %>% 
      add_field('request.headers.cookie',rename='parameter') %>%
      select(id, domain, parameter) %>% 
      filter(!is.na(parameter)) %>% 
      separate_rows(parameter, sep=";[:space:]*") %>% 
      separate(parameter, c('key','value'), sep="=", fill="right", extra="merge") %>%
      mutate(value=url_decode(value))
    
    referer_data <- get_requests_common() %>% 
      add_field('request.headers.referer') %>%
      bind_cols(urltools::url_parse(.$request.headers.referer)) %>% 
      select(id, domain, parameter) %>%
      filter(!is.na(parameter)) %>% 
      separate_rows(parameter, sep="&") %>% 
      separate(parameter, c('key','value'), sep="=", fill="right", extra="merge") %>%
      mutate(value=url_decode(value))
    
    domain_key_data <<- bind_rows(get=query_params, cookie=cookies, referer=referer_data, .id="type")
  }
  domain_key_data
}

add_field <- function(data, fields, rename=NA) {
  if (is.na(rename)) {
    rename <- fields
  }
  data %>% 
    left_join(
      get_requests_data() %>% 
        filter(field == fields) %>%
        select(id, !!rename:=value),
      by=c("id"="id")
    )
}

# Use with caution. But everything deleted by this should be reacreatable by functions in this file
delete_all_calculated_data <- function() {
  rm(domain_data,  pos = ".GlobalEnv")
  rm(passthrough_logs, pos = ".GlobalEnv")
  rm(requests_common, pos = ".GlobalEnv")
  rm(requests_data, pos = ".GlobalEnv")
  rm(domain_key_data, pos = ".GlobalEnv")
}

# Return all data for a given request ID (or vector of ids)
get_request <- function(ids) {
  requests_narrow %>% filter(id %in% ids)
}



# Export a bunch of data for use elsewhere. Mostly web interactives of graphics.
# This assumes data has been downloaded and imported using the `download.Rmd` notebook.
export_data <- function() {
  
  # This is the data we're working with limited by period
  # It's recalculated here so we don't have to rely on requests_narrow_period existing
  narrow <- requests_narrow_by_period(period) %>% mutate(prefix = substr(id, 0, prefix_length), group = substr(id, 0, group_length))
  
  narrow %>% 
    filter(field=='request.timestamp_start') %>% 
    spread(field, value, convert=T) %>% 
    mutate(timestamp = as.integer(round(request.timestamp_start/1000))) %>% 
    mutate(since = timestamp - as.integer(start)) %>%
    select(prefix, since) %>%
    #mutate(since = base64_enc(since)) %>%
    write_csv(here::here('data','exports','requests.csv'))
  
  plot_requests_histogram()
  ggsave('requests-histogram.png', path=here::here('plots'), dpi=1, width=700, height=300)
  
  plot_requests_histogram() + facet_wrap(~device, ncol=1)
  ggsave('requests-histogram-device.png', path=here::here('plots'), dpi=1, width=700, height=300)
  
  narrow %>% filter(field=='request.headers.user-agent') %>% count(value) %>% arrange(desc(n)) %>% write_csv(here::here('data','exports','user-agents.csv'))
  
}
  
