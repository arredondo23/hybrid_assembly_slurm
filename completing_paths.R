suppressMessages(library(Biostrings))
suppressMessages(library(seqinr))
suppressMessages(library(stringr))

path_nodes <- snakemake@input[["nodes"]]
path_links <- snakemake@input[["links"]]

links <- read.table(path_links)
colnames(links) <- c('L','Outgoing_node','Orientation','Incoming_node','Orientation','Additional_flag')

non_circular_links <- subset(links, links$Outgoing_node != links$Incoming_node)
nodes_to_complete <- unique(append(unique(non_circular_links$Outgoing_node), unique(non_circular_links$Incoming_node)))

nodes <- readDNAStringSet(filepath = path_nodes, format="fasta")

nodes_info <- data.frame(Contig_name = str_split_fixed(string = names(nodes), pattern = '_LN', n = 2)[,1],
                         Sequence = paste(nodes))

length_nodes <- str_split_fixed(string = names(nodes), pattern = ':', n = 5)[,3]
nodes_info$Length <- as.numeric(gsub(pattern = '_dp', replacement = '', x = length_nodes))

nodes_info$Contig_name <- gsub(pattern = 'S', replacement = '', x = nodes_info$Contig_name)

nodes_info <- subset(nodes_info, nodes_info$Contig_name %in% nodes_to_complete)
nodes_info <- subset(nodes_info, nodes_info$Length < 1e5)

suppressWarnings(write.fasta(sequences = as.list(nodes_info$Sequence), names = nodes_info$Contig_name, file.out = snakemake@output[["nodes_to_complete"]]))
