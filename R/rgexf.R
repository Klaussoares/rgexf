#' Decompose an edge list
#' 
#' Generates two data frames (nodes and edges) from a list of edges
#' 
#' `edge.list` transforms the input into a two-elements list containing a
#' dataframe of nodes (with columns \dQuote{id} and \dQuote{label}) and a
#' dataframe of edges. The last one is numeric (with columns \dQuote{source}
#' and \dQuote{target}) and based on auto-generated nodes' ids.
#' 
#' @param x A matrix or data frame structured as a list of edges
#' @return A list containing two data frames.
#' @author George Vega Yon 
#' 
#' Jorge Fabrega Lacoa 
#' @keywords manip
#' @examples
#' 
#'   edgelist <- matrix(
#'     c("matthew","john",
#'       "max","stephen",
#'       "matthew","stephen"),
#'     byrow=TRUE, ncol=2)
#'   
#'   edge.list(edgelist)
#' 
#' @export
edge.list <- function(x) {
################################################################################
# Translate a edgelist to two objects list (nodes + edges)
################################################################################
  objClass <- class(x)
  k        <- ncol(x)
  
  if (any(c("matrix", "data.frame") %in% objClass)) {
    
    if (k == 2) {
      # If it is not a factor
      if (!is.factor(x)) x <- factor(c(x[,1], x[,2]))
      edges <- matrix(unclass(x), byrow=FALSE, ncol=2)
      colnames(edges) <- c("source","target")
      nodes <- data.frame(id=1:nlevels(x), label=levels(x), stringsAsFactors=FALSE)
      
      return(list(nodes=nodes, edges=edges))
    }
    else stop("Insufficient number of columns (", k,")")
  }
  else stop("-", objClass, 
                  "- class not supported, try with a \"matrix\" or a \"data.frame\"")
}

.defAtt <- function(x, parent) {
################################################################################
# Prints the nodes and edges att definition
################################################################################
  apply(x, MARGIN=1,
        function(x, PAR) {
          XML::newXMLNode(name="attribute", parent=PAR, attrs=x)
        }, PAR=parent)
}

.addAtts <- function(tmpatt, attvec, tmpdoc=NULL) {
################################################################################
# Builds app proper XML attrs statement to be parsed by parseXMLAndAdd
################################################################################
  tmpatt <- data.frame(
    "for"=paste("att",attvec,sep=""), 
    value=unlist(tmpatt, recursive=FALSE), check.names=FALSE
    )

  for (i in attvec) 
    tmpdoc <- c(tmpdoc, .writeXMLLine("attvalue", tmpatt[i,,drop=FALSE ]) , sep="") 

  paste(c("<attvalues>", tmpdoc, "</attvalues>"), sep="", collapse="")
}

.writeXMLLine <- function(type, obj, finalizer=TRUE) {
################################################################################
# Builds as character whatever XML line is needed
################################################################################
  paste("<", type, " " ,
        paste(colnames(obj)[!is.na(obj)],obj[!is.na(obj)], sep="=\"", collapse="\" "),
        ifelse(finalizer, "\"/>","\">"), sep="")
}

.addNodesEdges <- function(dataset, PAR, type="node", doc) {
################################################################################
# Prints the nodes and edges
################################################################################  
  
  n <- NROW(dataset)
  vec <- 1:n
  xvars <- colnames(dataset)
  
  noattnames <- xvars[grep("(^att[0-9])|(^viz[.])", xvars, invert=T)]
  datasetnoatt <- dataset[, noattnames, drop=FALSE]
  
  # Parsing user-define attributes
  if (attributes <- length(grep("^att", xvars)) > 0) {
    attnames <- colnames(dataset)[grep("^att", xvars)]
    att <- dataset[,attnames, drop=FALSE]
    attvec <- 1:length(attnames)
  }
  
  # Parsing VIZ attributes
  if ((vizattributes <- length(grep("^viz[.]", xvars)) > 0)) {
    vizattnames <- colnames(dataset)[grep("^viz[.]", xvars)]
    
    # Color atts
    if ((vizcolors <- any(grepl("^viz[.]color",vizattnames)))) {
      vizcol.df <- dataset[,grep("^viz[.]color[.]", vizattnames, value=TRUE)]
      colnames(vizcol.df) <- gsub("^viz[.]color[.]", "", colnames(vizcol.df))
    }
    
    # Pos att
    if ((vizposition <- any(grepl("^viz[.]position",vizattnames)))) {
      vizpos.df <- dataset[,grep("^viz[.]position[.]", vizattnames, value=TRUE), drop=FALSE]
      colnames(vizpos.df) <- gsub("^viz[.]position[.]", "", colnames(vizpos.df))
    }
    
    # Size att
    if ((vizsize <- any(grepl("^viz[.]size",vizattnames)))) {
      vizsiz.df <- dataset[,grep("^viz[.]size[.]", vizattnames, value=TRUE), drop=FALSE]
      colnames(vizsiz.df) <- gsub("^viz[.]size[.]", "", colnames(vizsiz.df))
    }
    
    # Shape att
    if ((vizshape <- any(grepl("^viz[.]shape",vizattnames)))) {
      vizshp.df <- dataset[,grep("^viz[.]shape[.]", vizattnames, value=TRUE), drop=FALSE]
      colnames(vizshp.df) <- gsub("^viz[.]shape[.]", "", colnames(vizshp.df))
    }
    
    # Image att
    if ((vizimage <- any(grepl("^viz[.]image",vizattnames)))) {
      vizimg.df <- dataset[,grep("^viz[.]image[.]", vizattnames, value=TRUE), drop=FALSE]
      colnames(vizimg.df) <- c("value", "uri")
    }
    
    # Thickness att
    if ((viztness <- any(grepl("^viz[.]size",vizattnames)))) {
      vizthk.df <- dataset[,grep("^viz[.]size[.]", vizattnames, value=TRUE), drop=FALSE]
      colnames(vizthk.df) <- gsub("^viz[.]size[.]", "", colnames(vizthk.df))
    }
  }

  # Free memory
  rm(dataset)
  
  # Loop if there are not any attributes
  if (!attributes && !vizattributes) {
    for (i in vec) {
      XML::parseXMLAndAdd(.writeXMLLine(type, datasetnoatt[i,,drop=FALSE]),parent=PAR)
    }
    return(NULL)
  }
  
  # Loop if only there are attributes
  if (attributes && !vizattributes) {
    
    for (i in vec) {      
      # Adding directly
      XML::parseXMLAndAdd(
        paste(.writeXMLLine(type, datasetnoatt[i,,drop=FALSE], finalizer=FALSE), 
              .addAtts(att[i,], attvec), # Builds atts definition
              "</",type,">",sep=""),
        parent=PAR)
    }
    return(NULL)
  }
  
  # Loop if there are attributes and viz attributes
  for (i in vec) {
    # Node/Edge + Atts 
    if (attributes) {
      tempnode0 <- paste(
        .writeXMLLine(type, datasetnoatt[i,,drop=FALSE], finalizer=FALSE),
        .addAtts(att[i,], attvec), sep="")
    }
    else tempnode0 <- .writeXMLLine(type, datasetnoatt[i,,drop=FALSE], finalizer=FALSE)
    
    # Viz Att printing
    # Colors
    if (vizcolors) {
      tempnode0 <- paste(tempnode0, .writeXMLLine("color", vizcol.df[i,,drop=FALSE]),
                         sep="")
    }
    # Position
    if (vizposition) {
      tempnode0 <- paste(tempnode0, .writeXMLLine("position", vizpos.df[i,,drop=FALSE]),
                         sep="")
    }
    # Size
    if (vizsize) {
      tempnode0 <- paste(tempnode0, .writeXMLLine("size", vizsiz.df[i,1, drop=FALSE]),
                         sep="")
    }
    # Shape
    if (vizshape) {
      tempnode0 <- paste(tempnode0, .writeXMLLine("shape", vizshp.df[i,1,drop=FALSE]),
                         sep="")
    }
    # Image
    if (vizimage) {
      tempnode0 <- paste(tempnode0, .writeXMLLine("shape", vizimg.df[i,,drop=FALSE]),
                         sep="")
    }
    XML::parseXMLAndAdd(sprintf("%s</%s>",tempnode0, type), parent=PAR)
  }
  return(NULL)
}



#' Creates an object of class `gexf`
#' 
#' Takes a `node` matrix (or dataframe) and an
#' `edge` matrix (or dataframe) and creates a `gexf` object
#' containing a data-frame representation and a gexf representation of a graph.
#' 
#' @details
#' Just like `nodesVizAtt` and `edgesVizAtt`, `nodesAtt` and
#' `edgesAtt` must have the same number of rows as nodes and edges,
#' respectively. Using data frames is necessary as in this way data types are
#' preserved.
#' 
#' `nodesVizAtt` and `edgesVizAtt` allow using visual attributes such
#' as color, position (nodes only), size (nodes only), thickness (edges only)
#' shape and image (nodes only).  \itemize{ \item Color is defined by the RGBA
#' color model, thus for every node/edge the color should be specified through
#' a data-frame with columns *r* (red), *g* (green), *b* (blue)
#' with integers between 0 and 256 and a last column with *alpha* values
#' as a float between 0.0 and 1.0.  \item Position, for every node, it is a
#' three-column data-frame including *x*, *y* and *z*
#' coordinates. The three components must be float.  \item Size as a numeric
#' colvector (float values).  \item Thickness (see size).  \item Node Shape
#' (string), currently unsupported by Gephi, can take the values of
#' *disk*, *square*, *triangle*, *diamond* and
#' *image*.  \item Edge Shape (string), currently unsupported by Gephi, can
#' take the values of *solid*, *dotted*, *dashed* and
#' *double*.  \item Image (string), currently unsupported by Gephi,
#' consists on a vector of strings representing URIs.  }
#' 
#' `nodeDynamic` and `edgeDynamic` allow to draw dynamic graphs. It
#' should contain two columns *start* and *end*, both allowing
#' `NA` value. It can be use jointly with `tFormat` which by default
#' is set as \dQuote{double}. Currently accepted time formats are: \itemize{
#' \item Integer or double.  \item International standard *date*
#' yyyy-mm-dd.  \item dateTime W3 XSD
#' (http://www.w3.org/TR/xmlschema-2/#dateTime).  }
#' 
#' @param nodes A two-column data-frame or matrix of \dQuote{id}s and
#' \dQuote{label}s representing nodes.
#' @param edges A two-column data-frame or matrix containing \dQuote{source}
#' and \dQuote{target} for each edge. Source and target values are based on the
#' nodes ids.
#' @param edgesId A one-column data-frame, matrix or vector.
#' @param edgesLabel A one-column data-frame, matrix or vector.
#' @param edgesAtt A data-frame with one or more columns representing edges'
#' attributes.
#' @param edgesWeight A numeric vector containing edges' weights.
#' @param edgesVizAtt List of three or less viz attributes such as color, size
#' (thickness) and shape of the edges (see details)
#' @param nodesAtt A data-frame with one or more columns representing nodes'
#' attributes
#' @param nodesVizAtt List of four or less viz attributes such as color,
#' position, size and shape of the nodes (see details)
#' @param nodeDynamic A two-column matrix or data-frame. The first column
#' indicates the time at which a given node starts; the second one shows when
#' it ends. The matrix or data-frame must have the same number of rows than the
#' number of nodes in the graph.
#' @param edgeDynamic A two-column matrix or data-frame. The fist column
#' indicates the time at which a given edge stars; the second one shows when it
#' ends. The matrix or dataframe must have the same number of rows than the
#' number of edges in the graph.
#' @param digits Integer. Number of decimals to keep for nodes/edges sizes. See
#' [print.default()]
#' @param output String. The complete path (including filename) where to export
#' the graph as a GEXF file.
#' @param tFormat String. Time format for dynamic graphs (see details)
#' @param defaultedgetype \dQuote{directed}, \dQuote{undirected},
#' \dQuote{mutual}
#' @param meta A List. Meta data describing the graph
#' @param keepFactors Logical, whether to handle factors as numeric values
#' (`TRUE`) or as strings (`FALSE`) by using `as.character`.
#' @param encoding Encoding of the graph.
#' @param vers Character scalar. Version of the GEXF format to generate.
#' By default `"1.3"`.
#' @param ... Passed to `gexf`.
#' @param rescale.node.size Logical scalar. When `TRUE` it rescales the 
#' size of the vertices such that the largest one is about \%5 of the plotting
#' region.
#' @return A `gexf` class object (list). Contains the following: \itemize{
#' \item `meta` : (list) Meta data describing the graph.  \item
#' `mode` : (list) Sets the default edge type and the graph mode.  \item
#' `atts.definitions`: (list) Two data-frames describing nodes and edges
#' attributes.  \item `nodesVizAtt` : (data-frame) A multi-column
#' data-frame with the nodes' visual attributes.  \item `edgesVizAtt` :
#' (data-frame) A multi-column data-frame with the edges' visual attributes.
#' \item `nodes` : (data-frame) A two-column data-frame with nodes' ids
#' and labels.  \item `edges` : (data-frame) A five-column data-frame with
#' edges' ids, labels, sources, targets and weights.  \item `graph` :
#' (String) GEXF (XML) representation of the graph.  }
#' @author George Vega Yon 
#' 
#' Jorge Fabrega Lacoa 
#' @seealso [new.gexf.graph()]
#' @references The GEXF project website: http://gexf.net
#' @keywords IO
#' @examples
#' 
#' if (interactive()) {
#'   demo(gexf) # Example of gexf command using fictional data.
#'   demo(gexfattributes) # Working with attributes.
#'   demo(gexfbasic) # Basic net.
#'   demo(gexfdynamic) # Dynamic net.
#'   demo(edge.list) # Working with edges lists.
#'   demo(gexffull) # All the package.
#'   demo(gexftwitter) # Example with real data of chilean twitter accounts.
#'   demo(gexfdynamicandatt) # Dynamic net with static attributes.
#'   demo(gexfbuildfromscratch) # Example building a net from scratch.
#'   demo(gexfrandom)
#' }
#' 
#' @name gexf-class
NULL

default_nodeVizAtt <- list(
  size     = function() 8.0,
  position = function() structure(c(runif(2, -200, 200), 0), names = c("x", "y", "z")),
  color    = function() "tomato"
)

set_default_nodeVizAtt <- function() {
  
  # Getting parameters
  env <- parent.frame()
  n <- nrow(env[["nodes"]])
  
  # Checking viz attributes
  for (att in names(default_nodeVizAtt))
    if (!length(env[["nodesVizAtt"]][[att]])) {
      
      env[["nodesVizAtt"]][[att]] <- do.call(
        rbind,
        lapply(1L:n, function(i) default_nodeVizAtt[[att]]())
      )
        
    }

}

#' @export
#' @rdname gexf-class
gexf <- function(
  ################################################################################  
  # Prints the gexf file
  ################################################################################
  nodes,
  edges,
  edgesLabel=NULL,
  edgesId=NULL,
  edgesAtt=NULL,
  edgesWeight=NULL,
  edgesVizAtt = list(color=NULL, size=NULL, shape=NULL),
  nodesAtt=NULL,
  nodesVizAtt = list(color=NULL, position=NULL, size=NULL, shape=NULL, image=NULL),
  nodeDynamic=NULL,
  edgeDynamic=NULL,
  digits=getOption("digits"),
  output = NA,
  tFormat="double",
  defaultedgetype = "undirected",
  meta = list(
    creator     = "NodosChile",
    description = "A GEXF file written in R with \"rgexf\"",
    keywords    = "GEXF, NodosChile, R, rgexf, Gephi"
    ),
  keepFactors = FALSE,
  encoding = "UTF-8",
  vers     = "1.3",
  rescale.node.size = TRUE
) {
  
  ##############################################################################
  # CLASS CHECKS AND OTHERS CHECKS
  
  # Nodes
  if (inherits(nodes, c("data.frame", "matrix"))) {
    if (ncol(nodes) != 2)
      stop("-nodes- should have two columns not ", ncol(nodes))
  }
  else
    stop("Invalid object type: -nodes- should be a two column data.frame or a matrix")
  
  # Edges
  if (inherits(edges, c("data.frame", "matrix"))) {
    if (ncol(edges) != 2)
      stop("-edges- should have two columns not ", ncol(edges))
  }
  else
    stop("Invalid object type: -edges- should be a two column data.frame or a matrix")
  
  # version
  vers <- gexf_version(vers)
  n <- nrow(nodes)
  m <- nrow(edges)
  
  # Edges Label
  .parseEdgesLabel(edgesLabel, edges)
  
  # Parsing Edges Id
  edgesId <- .parseEdgesId(edgesId, edges)
  
  # Parsing Edges Att
  nEdgesAtt <- .parseEdgesAtt(edgesAtt, edges)
  
  # Parsing edges Weight
  .parseEdgesWeight(edgesWeight, edges)
  
  # Parsing edges Viz Att
  edgesVizAtt  <- if (length(unlist(edgesVizAtt))) {
    nodesVizAtt <- nodesVizAtt[sapply(edgesVizAtt, length) > 0]
    Map(function(a, b) parseVizAtt(a, b, m, "edges"), a=names(edgesVizAtt),
        b=edgesVizAtt)
  } else NULL
  
  nEdgesVizAtt <- length(edgesVizAtt)
  # nEdgesVizAtt <- .parseEdgesVizAtt(edgesVizAtt, edges)
  
  # Nodes Att
  nNodesAtt <- .parseNodesAtt(nodesAtt, nodes)
  
  # Parsing nodes Viz Atts
  set_default_nodeVizAtt()
  
  # Rescaling vertex sizes if required
  if (rescale.node.size) {
    
    # Rescaling and centering position
    for (i in 1:3) {
      
      pran <- range(nodesVizAtt$position[, i])
      
      if (pran[1] == pran[2])
        next
      
      nodesVizAtt$position[, i] <- ((nodesVizAtt$position[, i] - pran[1])/
        (pran[2] - pran[1]))*200 - 100
      
    }
      
    # Getting ranges
    sscale <- 200*.05
    
    nodesVizAtt$size <- nodesVizAtt$size/max(nodesVizAtt$size)*sscale
    
  }
  
  nodesVizAtt  <- if (length(unlist(nodesVizAtt))) {
    
    # # Removing empty ones
    nodesVizAtt <- nodesVizAtt[sapply(nodesVizAtt, length) > 0]
    Map(function(a, b) parseVizAtt(a, b, n, "nodes"), a=names(nodesVizAtt),
                        b=nodesVizAtt)
  } else NULL
  
    nNodesVizAtt <- length(nodesVizAtt)
  
  # Checking the number of digits
  if (!is.integer(digits)) stop("Invalid number of digits ",digits,
                                ".\n Must be a number between 0 and 22")
  fmt <- sprintf("%%.%gg", digits)
  
  # Dynamics
  dynamic <- c(FALSE, FALSE)

  if (length(nodeDynamic) > 0) {
    if (is.data.frame(nodeDynamic) | is.matrix(nodeDynamic)) {
      if (NROW(nodeDynamic) == NROW(nodes)) dynamic[1] <- TRUE
      else stop("Insufficient number of rows: -nodeDynamic- (",NROW(nodeDynamic), 
                " rows) should have the same number of rows than nodes there are (",
                NROW(nodes),")")
    } else stop("Invalid object type: -nodeDynamic- should be a two columns data.frame or a matrix")
  }
  
  if (length(edgeDynamic) > 0) {
    if (is.data.frame(edgeDynamic) | is.matrix(edgeDynamic)) {
      if (NROW(edgeDynamic) == NROW(edges)) dynamic[2] <- TRUE
      else stop("Insufficient number of rows: -edgeDynamic- (",NROW(edgeDynamic), " rows) should have the same number of rows than edges there are (", NROW(edges),")")
    } else stop("Invalid object type: -edgeDynamic- should be a two columns data.frame or a matrix")
  }
  
  ##############################################################################
  # Strings
  old.strAF <- getOption("stringsAsFactors")
  on.exit(options(stringsAsFactors = old.strAF))
  options(stringsAsFactors = FALSE)
  
  if (!any(dynamic)) mode <- "static" else mode <- "dynamic"
  
  # Starting xml
  xmlFile <- XML::newXMLDoc(addFinalizer=TRUE)
  gexf <- XML::newXMLNode(name="gexf", doc = xmlFile)
  
  # gexf att
  
  XML::newXMLNamespace(node=gexf, namespace=vers$xmlns)
  XML::newXMLNamespace(
    node=gexf, namespace=vers$`xmlns:vis`, prefix="viz")
  XML::newXMLNamespace(
    node=gexf, namespace="http://www.w3.org/2001/XMLSchema-instance",
    prefix="xsi"
  ) 
  
  XML::xmlAttrs(gexf) <- c( 
    "xsi:schemaLocation" = vers$`xsi:schemaLocation`, version=vers$number)
  
  # graph
  xmlMeta <- XML::newXMLNode(name="meta", 
                        attrs=list(lastmodifieddate=as.character(Sys.Date())), 
                        parent=gexf)
  XML::newXMLNode(name="creator", meta$creator, parent=xmlMeta)
  XML::newXMLNode(name="description", meta$description, parent=xmlMeta)
  XML::newXMLNode(name="keywords", meta$keywords, parent=xmlMeta)
  
  xmlGraph <- XML::newXMLNode(name="graph", parent=gexf)
  if (mode == "dynamic") {
    
    # Fixing time factors
    if (keepFactors) {
      
      for(i in 1:2) {
        
        if (dynamic[1])
          nodeDynamic[,i] <- as.numeric(nodeDynamic[,i])
        
        if (dynamic[2])
          edgeDynamic[,i] <- as.numeric(edgeDynamic[,i])
        
      }
      
    } else {
      
      for(i in 1:2) {
        
        if (dynamic[1])
          nodeDynamic[,i] <- as.character(nodeDynamic[,i])
        
        if (dynamic[2])
          edgeDynamic[,i] <- as.character(edgeDynamic[,i])
        
      }
      
    }
    
    strTime <- c(unlist(nodeDynamic),unlist(edgeDynamic))

    endTime <- strTime
    
    # Checking start and ends
    strTime <- min(strTime, na.rm=TRUE)
    endTime <- max(endTime, na.rm=TRUE)
    
    XML::xmlAttrs(xmlGraph) <- c(mode=mode, start=strTime, end=endTime,
                            timeformat=tFormat, defaultedgetype=defaultedgetype)
        
    # Replacing NAs
    if (dynamic[1]) {
      
      nodeDynamic[is.na(nodeDynamic[,1]),1] <- strTime
      nodeDynamic[is.na(nodeDynamic[,2]),2] <- endTime
      
    }
    
    if (dynamic[2]) {
      
      edgeDynamic[is.na(edgeDynamic[,1]),1] <- strTime
      edgeDynamic[is.na(edgeDynamic[,2]),2] <- endTime
      
    }
    
  } else 
    XML::xmlAttrs(xmlGraph) <- c(mode=mode, defaultedgetype=defaultedgetype)
  
  datatypes <- matrix(
    c(
      "string", "character",
      "integer", "integer",
      "float", "double",
      "boolean", "logical"
    ), byrow=TRUE, ncol =2)
  
  # nodes att definitions
  if (nNodesAtt > 0) {
    TIT <- colnames(nodesAtt)
    TYPE <- unlist(lapply(nodesAtt, typeof))
    CLASS <- unlist(lapply(nodesAtt, class))
    
    # Checks for factors (factor replacing is done later)
    if (keepFactors) TYPE[CLASS == "factor"] <- "integer"
    else TYPE[CLASS == "factor"] <- "string"
    
    nodesAttDf <- data.frame(
      id = paste("att",1:nNodesAtt,sep=""), 
      title = TIT, 
      type = TYPE
    )
    
    # Fixing datatype
    for (i in 1:NROW(datatypes)) {
      nodesAttDf$type <- gsub(datatypes[i,2], datatypes[i,1], nodesAttDf$type)
    }
    
    xmlAttNodes <- XML::newXMLNode(name="attributes", parent=xmlGraph)
    XML::xmlAttrs(xmlAttNodes) <- c(class="node", mode="static")
    .defAtt(nodesAttDf, parent=xmlAttNodes)
    
  } 
  else {
    nodesAttDf <- NULL
  }
  
  # edges att
  if (nEdgesAtt > 0) {
    TIT <- colnames(edgesAtt)
    TYPE <- unlist(lapply(edgesAtt, typeof))
    CLASS <- unlist(lapply(edgesAtt, class))
    
    # Checks for factors (factor replacing is done later)
    if (keepFactors) TYPE[CLASS == "factor"] <- "integer"
    else TYPE[CLASS == "factor"] <- "string"
    
    edgesAttDf <- data.frame(
      id = paste("att",1:nEdgesAtt,sep=""), 
      title = TIT, 
      type = TYPE
    )
    
    # Fixing datatype
    for (i in 1:NROW(datatypes)) {
      edgesAttDf$type <- gsub(datatypes[i,2], datatypes[i,1], edgesAttDf$type)
    }
    
    xmlAttEdges <- XML::newXMLNode(name="attributes", parent=xmlGraph)
    XML::xmlAttrs(xmlAttEdges) <- c(class="edge", mode="static")
    .defAtt(edgesAttDf, parent=xmlAttEdges)
  } 
  else {
    edgesAttDf <- NULL
  }
  
  # nodes vizatt ---------------------------------------------------------------
  ListNodesVizAtt <- if (nNodesVizAtt > 0)
    do.call(cbind, unname(nodesVizAtt))
  else
    NULL
  
  nodesVizAtt     <- lapply(nodesVizAtt, function(x) {
    colnames(x) <- gsub("^viz[.][a-zA-Z]+[.]", "", colnames(x))
    x
  })
  
  
  # edges vizatt ---------------------------------------------------------------
  ListEdgesVizAtt <- if (nEdgesVizAtt >0) 
    do.call(cbind, unname(edgesVizAtt))
  else
    NULL
  
  edgesVizAtt <- lapply(edgesVizAtt, function(x) {
    colnames(x) <- gsub("^viz[.][a-zA-Z]+[.]", "", colnames(x))
    x
  })
  
  ##############################################################################
  # The basic char matrix definition  for nodes
  
  if (dynamic[1])
    nodeDynamic <- as.data.frame(nodeDynamic)
  
  if (nNodesAtt > 0)
    nodesAtt <- data.frame(nodesAtt)
  
  for (set in c(nodeDynamic, nodesAtt, ListNodesVizAtt)) {
    try(nodes <- data.frame(nodes, set), silent=TRUE)
  }
  
  # Naming the columns
  attNames <- nodesAttDf["id"]
  if (!is.null(nodeDynamic))
    tmeNames <- c("start", "end")
  else
    tmeNames <- NULL
  
  colnames(nodes) <- unlist(
    c("id", "label", tmeNames, attNames, colnames(ListNodesVizAtt))
    )
  
  # Fixing factors
  if (keepFactors) {
    
    tofix <- which(lapply(nodes, class) %in% "factor")
    if (length(tofix)) {
      
      warning("Factor variables will be stored as -numeric-.",
              "\nIf you don't want this behavior, set -keepFactors- as -FALSE-.")
      
      nodes[,tofix] <- lapply(nodes[,tofix,drop=FALSE], as.numeric)
      
    }
    
  } else {
    
    tofix <- which(lapply(nodes, class) %in% "factor")
    if (length(tofix))
      nodes[,tofix] <- lapply(nodes[,tofix,drop=FALSE], as.character)
    
  }
  
  # NODES
  xmlNodes <- XML::newXMLNode(name="nodes", parent=xmlGraph)
  .addNodesEdges(nodes, xmlNodes, "node")
  
  ##############################################################################
  # The basic dataframe definition  for edges  
  
  if (dynamic[2]) edgeDynamic <- as.data.frame(edgeDynamic)
  
  if (nEdgesAtt > 0) edgesAtt <- data.frame(edgesAtt)
  
  # Adding edge id
  try(edgesId <- cbind(edgesId, edgesLabel), silent=TRUE)
  edges <- cbind(edgesId, edges)
  for (set in c(edgeDynamic, edgesAtt, ListEdgesVizAtt)) {
    try(edges <- data.frame(edges, set), silent=TRUE)
  }
  
  # Naming the columns
  attNames <- edgesAttDf["id"]
  if (!is.null(edgeDynamic))
    tmeNames <- c("start", "end")
  else
    tmeNames <- NULL
  
  # Generating weights
  if (!length(edgesWeight))  edgesWeight <- 1
  edges <- data.frame(edges, x=as.numeric(edgesWeight))
  edges$x <- sprintf(fmt, edges$x)
  
  # Seting colnames
  if (length(edgesLabel) > 0) edgesLabelCName <- "label"
  else edgesLabelCName <- NULL
  colnames(edges) <- unlist(c("id", edgesLabelCName, "source", "target", 
                              tmeNames, attNames, colnames(ListEdgesVizAtt),
                              "weight"))
  
  # EDGES
  xmlEdges <- XML::newXMLNode(name="edges", parent=xmlGraph)
  
  # Fixing factors
  if (keepFactors) {
    
    for (i in colnames(edges)) {
      
      if (class(edges[[i]]) == "factor")
        edges[[i]] <- as.numeric(edges[[i]])
      
    }
    
  } else {
    
    for (i in colnames(edges)) {
      
      if (class(edges[[i]]) == "factor")
        edges[[i]] <- as.character(edges[[i]])
      
    } 
    
  }
  
  # Adding edges
  .addNodesEdges(edges, xmlEdges, "edge")
  
  # Edges Label (for data frame)
  if (length(edgesLabel) == 0) edgesLabel <- edges[,"id"]
    
  results <- build.and.validate.gexf(
    meta             = meta,
    mode             = list(defaultedgetype=defaultedgetype, mode=mode),
    atts.definitions = list(nodes = nodesAttDf, edges = edgesAttDf),
    nodesVizAtt      = nodesVizAtt,
    edgesVizAtt      = edgesVizAtt,
    nodes            = as.data.frame(nodes),
    edges            = as.data.frame(cbind(edges,edgesLabel)),
    graph            = XML::saveXML(xmlFile, encoding=encoding)
    )
  
  
  # Fixing 
  for (viz in c("color", "size", "shape", "position")) 
    results$graph <- gsub(
      sprintf("<%s",viz),
      sprintf("<viz:%s", viz), 
      results$graph,
      fixed=TRUE)
  
  
  # Returns
  if (is.na(output)) {
    
    return(results)
    
  } else {
    # warning("Starting version 0.17.0")
    
    write.gexf(results, output=output, replace=TRUE)
    
  }
}


#' @export
#' @rdname gexf-class
write.gexf <- function(nodes, ...) {
  
  if (!inherits(nodes, "gexf")) {
    gexf(nodes, ...)
    
  } else if (length(list(...)$output)) {
    
    output <- list(...)$output
    
    f <- file(description = output, open="w",encoding='UTF-8')
    write(nodes$graph, file=f)
    close.connection(f)
    message('GEXF graph successfully written at:\n',normalizePath(output))
    return(invisible(nodes))
    
  }
}


