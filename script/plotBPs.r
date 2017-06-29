library(scales)
library(ggplot2)
library(dplyr)
library(RColorBrewer)


get_data <- function(infile = "all_bps_new.txt"){
    data<-read.delim(infile, header = F)
    colnames(data) <- c("event", "bp_no", "sample", "chrom", "bp", "gene", "feature", "type", "length")
  
  	#filter on chroms
    data <- filter(data, chrom != "Y" & chrom != "4")
  
  	#filter out samples
    data<-filter(data, sample != "A373R1" & sample != "A373R7" & sample != "A512R17" )
    dir.create(file.path("plots"), showWarnings = FALSE)
	return(data)
}

clean_theme <- function(base_size = 12){
  theme(
    plot.title = element_text(hjust = 0.5, size = 20),
    panel.background = element_blank(),
    plot.background = element_rect(fill = "transparent",colour = NA),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank(),
    axis.line.x = element_line(color="black", size = 0.5),
    axis.line.y = element_line(color="black", size = 0.5),
    axis.text = element_text(size=20),
    axis.title = element_text(size=30)
    )
}


plot_all_chroms_grid <- function(object=NA){
  
  data<-get_data()

  if(is.na(object)){
    object<-'type'
  }
  
  cat("Plotting SVs by", object, "\n")
  
  p<-ggplot(data)
  p<-p + geom_histogram(aes(bp/1000000, fill = get(object)), binwidth=0.1, alpha = 0.8)  
  p<-p + facet_wrap(~chrom, scale = "free_x", ncol = 2)
  p<-p + scale_x_continuous("Mbs", breaks = seq(0,33,by=1), limits = c(0, 33),expand = c(0.01, 0.01))
  p<-p + scale_y_continuous("Number of Breakpoints", expand = c(0.01, 0.01))
  p<-p + clean_theme() +
      theme(
	  axis.text.x = element_text(angle = 45, hjust=1),
	  axis.text = element_text(size=12),
	  axis.title = element_text(size=20),
      strip.text.x = element_text(size = 15)
	  )
  
  if (object == 'type'){
    p<-p + scale_fill_brewer(palette = "Set2")
  }
  
  chrom_outfile <- paste("Breakpoints_chroms_by_", object, ".pdf", sep = "")
  cat("Writing file", chrom_outfile, "\n")
  ggsave(paste("plots/", chrom_outfile, sep=""), width = 20, height = 10)
  p
}

bps_per_chrom <- function(type=T){

  data<-get_data()
  chromosomes <- c("2L", "2R", "3L", "3R", "X", "Y", "4")
  lengths <- c(23513712, 25286936, 28110227, 32079331, 23542271, 3667352, 1348131)

  karyotype <- setNames(as.list(lengths), chromosomes)

  for (c in chromosomes) {
    len<-karyotype[[c]]
    len<-len/1000000
    
    cat("Chrom", c, "length:", len, sep = " ",  "\n")

    per_chrom<-filter(data, chrom == c)

    p<-ggplot(per_chrom)
    p<-p + geom_histogram(aes(bp/1000000, fill = type), binwidth=0.1, alpha = 0.8)
    p<-p + scale_fill_brewer(palette = "Set2")
    p<-p + scale_x_continuous("Mbs", breaks = seq(0,len,by=1), limits = c(0, len+0.1),expand = c(0.01, 0.01))
    p<-p + scale_y_continuous("Number of Breakpoints", limits = c(0, 35), expand = c(0.01, 0.01))
    p<-p + clean_theme() +
      theme(
        axis.text.x = element_text(angle = 45, hjust=1),
        axis.title = element_text(size=20)
      )
    p <- p + ggtitle(paste("Chromosome: ", c))

    if (type){
      per_chrom <- paste("Breakpoints_type_", c, ".pdf", sep = "")
    }
    else{
      per_chrom <- paste("Breakpoints_sample", c, ".pdf", sep = "")
    }
    
    cat("Writing file", per_chrom, "\n")
    ggsave(paste("plots/", per_chrom, sep=""), width = 20, height = 10)
  }
}


bp_features <- function(){
  data<-get_data()
  
  # To condense exon counts into "exon"
  data$feature <- gsub("_.*","",data$feature)
  
  # Reoders descending
  data$feature <- factor(data$feature, levels = names(sort(table(data$feature), decreasing = TRUE)))

  p<-ggplot(data)
  p<-p + geom_bar(aes(feature, fill = feature))
  p<-p + scale_fill_brewer(palette = "Set2")
  p<-p + clean_theme() +
    theme(axis.title.x=element_blank(),
          panel.grid.major.y = element_line(color="grey80", size = 0.01)
		  )
  p<-p + scale_x_discrete(expand = c(0.01, 0.01))
  p<-p + scale_y_continuous(expand = c(0.01, 0.01))
  
  features_outfile <- paste("Breakpoints_features_count", ".pdf", sep = "")
  cat("Writing file", features_outfile, "\n")

  ggsave(paste("plots/", features_outfile, sep=""), width = 20, height = 10)

  p
}

sv_types<-function(){
  data<-get_data()
  
  # Reorder by count
  data$type <- factor(data$type, levels = names(sort(table(data$type), decreasing = TRUE)))

  # Only take bp1 for each event
  data<-filter(data, bp_no != "bp2")

  p<-ggplot(data)
  p<-p + geom_bar(aes(type, fill = type))
  p<-p + scale_fill_brewer(palette = "Set2")
  p<-p + clean_theme() +
    theme(axis.title.x=element_blank(),
          panel.grid.major.y = element_line(color="grey80", size = 0.01)
		  )
  p<-p + scale_x_discrete(expand = c(0.01, 0.01))
  p<-p + scale_y_continuous(expand = c(0.01, 0.01))

  types_outfile <- paste("Breakpoints_types_count", ".pdf", sep = "")
  cat("Writing file", types_outfile, "\n")

  ggsave(paste("plots/", types_outfile, sep=""), width = 20, height = 10)

  p
}

feature_lengths<-function(size_threshold = NA){
  data<-get_data()
  
  # Only take bp1 for each event
  data<-filter(data, type != "TRA", type != "BND", bp_no != "bp2")

  data$length<-(data$length/1000)

  if(is.na (size_threshold)){
    size_threshold<-max(data$length)
  }
  
  if(size_threshold <= 1){
    breaks <- 0.1
  }
  else{
    breaks <- 1
  }
  
  p<- ggplot(data, aes(length))
  p<-p + geom_density(aes(fill = type), alpha = 0.4)
  p<-p + clean_theme()
  p<-p + scale_x_continuous("Size in Mb", expand = c(0,0), breaks = seq(0,size_threshold,by=breaks), limits=c(0, size_threshold))
  p<-p + scale_y_continuous(expand = c(0,0))

  sv_classes_len_outfile <- paste("Classes_lengths", ".pdf", sep = "")
  cat("Writing file", sv_classes_len_outfile, "\n")

  ggsave(paste("plots/", sv_classes_len_outfile, sep=""), width = 20, height = 10)

  p
}

notch_hits<-function(){
  data<-get_data()
  data<-filter(data, chrom == "X", bp >= 3000000, bp <= 3300000)
  
  p<-ggplot(data)
  p<-p + geom_point(aes(bp/1000000, sample, colour = sample, shape = type, size = 2))
  p<-p + clean_theme() +
    theme(axis.title.y=element_blank(),
          panel.grid.major.y = element_line(color="blue", size = 0.05)
		  )
  p<-p + scale_x_continuous("Mb", expand = c(0,0), breaks = seq(3,3.3,by=0.05), limits=c(3, 3.301))
  
  p <- p + annotate("rect", xmin=3.000000, xmax=3.134532, ymin=0, ymax=0.5, alpha=.2, fill="green")
  p <- p + annotate("rect", xmin=3.134870, xmax=3.172221, ymin=0, ymax=0.5, alpha=.2, fill="skyblue")
  p <- p + annotate("rect", xmin=3.176440, xmax=3.300000, ymin=0, ymax=0.5, alpha=.2, fill="red")
  p 

}
