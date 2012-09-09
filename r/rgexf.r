.defAtt <- function(x, parent) {
################################################################################
# Prints the nodes and edges att definition
################################################################################  
  apply(x, MARGIN=1,
        function(x, PAR) {
          newXMLNode(name='attribute', parent=PAR, attrs=x)
        }, PAR=parent)
}

.addNodesEdges <- function(x, parent, type='node') {
################################################################################
# Prints the nodes and edges
################################################################################  
apply(x, MARGIN = 1, 
        function(x, PAR, type) {
          x <- data.frame(t(x), stringsAsFactors=F)

          xvars <- names(x)
          
          noattnames <- xvars[grep('^att', xvars, invert=T)]
          
          # Parsing user-define attributes
          attributes <- length(grep('^att', xvars)) > 0
          if (attributes) {
            att <- x[,grep('^att', xvars)]            
            attnames <- names(att)
          }
          else attnames <- ""
          
          # Parsing VIZ attributes
          vizattributes <- length(grep('^viz[:]', xvars)) > 0
          if (attributes) {
            vizatt <- x[,grep('^vizatt', xvars)]            
            vizattnames <- names(vizatt)
          }
          else vizattnames <- ""
          
          tempnode0 <- newXMLNode(name=type, parent=PAR)
          
          # Adds every attribute removing leading and ending spaces
          for (i in noattnames) {
            tempatt <- x[,c(i)]
            if (!is.na(tempatt)) xmlAttrs(tempnode0)[i] <-
              gsub("[\t ]*$", "", gsub("^[\t ]*", "", tempatt))
          }
          
          # Viz Att printing
          if (vizattributes) {
            tempDF <- data.frame(names(vizatt), value=t(vizatt), stringsAsFactors=F)
            tempnode1 <- newXMLNode(name=1)
          }
          # Attributes printing        
          if (attributes) {      
            tempDF <- data.frame(names(att), value=t(att), stringsAsFactors=F)

            colnames(tempDF) <- c('for', 'value')
            
            tempnode2 <- newXMLNode('attvalues', parent=tempnode0)
            
            apply(tempDF, MARGIN = 1, function(x) {
              newXMLNode(name='attvalue', parent=tempnode2, attrs=x)
            })
          }
        }, PAR=parent, type=type)
}

gexf <- function(
################################################################################  
# Prints the gexf file
################################################################################
  nodes,
  edges,
  edgesAtt=NULL,
  edgesWeight=NULL,
  edgesVizAtt = NULL,
  nodesAtt=NULL,
  nodesVizAtt = NULL,
  nodeDynamic=NULL,
  edgeDynamic=NULL,
  output = NA,
  tFormat='double',
  defaultedgetype = 'undirected'
  ) {
  require(XML, quietly = T)
  
  # Defining paramters
  nEdgesAtt <- ifelse(length(edgesAtt) > 0, NCOL(edgesAtt), 0)
  nNodesAtt <- ifelse(length(nodesAtt) > 0, NCOL(nodesAtt), 0)
  nNodesVizAtt <- ifelse(length(nodesVizAtt) > 0, NCOL(nodesVizAtt), 0)
  nEdgesVizAtt <- ifelse(length(edgesVizAtt) > 0, NCOL(edgesVizAtt), 0)
  dynamic <- c(length(nodeDynamic) > 0 , length(edgeDynamic) > 0)
  
  if (!any(dynamic)) mode <- 'static' else mode <- 'dynamic'

  # Starting xml
  xmlFile <- newXMLDoc(addFinalizer=T)
  gexf <- newXMLNode(name='gexf', doc = xmlFile)
  
  # gexf att

  newXMLNamespace(node=gexf, namespace='http://www.gexf.net/1.2draft')
  newXMLNamespace(
    node=gexf, namespace='http://www.gexf.net/1.1draft/viz', prefix='viz')
  newXMLNamespace(
    node=gexf, namespace='http://www.w3.org/2001/XMLSchema-instance',
    prefix='xsi'
  ) 
  
  xmlAttrs(gexf) <- c( 
    'xsi:schemaLocation' = 'http://www.gexf.net/1.2draft http://www.gexf.net/1.2draft/gexf.xsd',
    version=1.2)
  
  # graph
  xmlGraph <- newXMLNode(name='graph', parent=gexf)
  if (mode == 'dynamic') {
    strTime <- min(c(unlist(nodeDynamic), unlist(edgeDynamic)), na.rm=T)
    endTime <- max(c(unlist(nodeDynamic), unlist(edgeDynamic)), na.rm=T)
    xmlAttrs(xmlGraph) <- c(mode=mode, start=strTime, end=endTime,
                            timeformat=tFormat, defaultedgetype=defaultedgetype)
    
    
  } else {
    xmlAttrs(xmlGraph) <- c(mode=mode)
  }

  datatypes <- matrix(
    c(
      'string', 'character',
      'integer', 'integer',
      'float', 'double',
      'boolean', 'logical'
      ), byrow=T, ncol =2)
  
  # nodes att definitions
  if (nNodesAtt > 0) {
    if (nNodesAtt == 1) {
      TIT <- 'att1'; TYPE <- typeof(nodesAtt) 
    }
    else {
      TIT <- colnames(nodesAtt); TYPE <- sapply(nodesAtt, typeof)
    }
    
    nodesAttDf <- data.frame(
      id = paste('att',1:nNodesAtt,sep=''), title = TIT, type = TYPE,
      stringsAsFactors=F
    )
    
    # Fixing datatype
    for (i in 1:NROW(datatypes)) {
      nodesAttDf$type <- gsub(datatypes[i,2], datatypes[i,1], nodesAttDf$type)
    }
    
    xmlAttNodes <- newXMLNode(name='attributes', parent=xmlGraph)
    xmlAttrs(xmlAttNodes) <- c(class='node', mode='static')
    .defAtt(nodesAttDf, parent=xmlAttNodes)
    
  } 
  else {
    nodesAttDf <- NULL
  }

  # edges att
  if (nEdgesAtt > 0) {
    if (nEdgesAtt == 1) {
      TIT <- 'att1'; TYPE <- typeof(edgesAtt) 
    }
    else {
      TIT <- colnames(edgesAtt); TYPE <- sapply(edgesAtt, typeof)
    }
    
    edgesAttDf <- data.frame(
      id = paste('att',1:nEdgesAtt,sep=''), title = TIT, type = TYPE,
      stringsAsFactors=F
      )
    
    # Fixing datatype
    for (i in 1:NROW(datatypes)) {
      edgesAttDf$type <- gsub(datatypes[i,2], datatypes[i,1], edgesAttDf$type)
    }
    
    xmlAttEdges <- newXMLNode(name='attributes', parent=xmlGraph)
    xmlAttrs(xmlAttEdges) <- c(class='edge', mode='static')
    .defAtt(edgesAttDf, parent=xmlAttEdges)
  } 
  else {
    edgesAttDf <- NULL
  }
  
  # nodes vizatt
  if (nNodesVizAtt > 0) {
    colnames(nodesVizAtt) <- paste(viz,colnames(nodesVizAtt),sep=":")
  }
  
  ##############################################################################
  # The basic char matrix definition  for nodes
  nodes <- as.matrix(nodes)
  if (dynamic[1]) nodeDynamic <- as.matrix(nodeDynamic)
  if (nNodesAtt > 0) nodesAtt <- as.matrix(nodesAtt)
  if (nNodesVizAtt > 0) nodesVizAtt <- as.matrix(nodesVizAtt)
  
  nodes <- cbind(nodes, nodeDynamic, nodesAtt, nodesVizAtt)
  
  # Naming the columns
  attNames <- nodesAttDf['id']
  if (!is.null(nodeDynamic)) tmeNames <- c('start', 'end') else tmeNames <- NULL
    
  colnames(nodes) <- unlist(c('id', 'label', tmeNames, attNames))
  
  # NODES
  xmlNodes <- newXMLNode(name='nodes', parent=xmlGraph)
  .addNodesEdges(nodes, xmlNodes, 'node')

  ##############################################################################
  # The basic dataframe definition  for edges
  if (dynamic[2]) edgeDynamic <- as.matrix(edgeDynamic)
  if (nEdgesAtt > 0) edgesAtt <- as.matrix(edgesAtt)
  if (nEdgesVizAtt > 0) edgesVizAtt < as.matrix(edgesVizAtt) 
    
  edges <- cbind(edges, edgeDynamic, edgesAtt, edgesVizAtt)
    
  # Naming the columns
  attNames <- edgesAttDf['id']
  if (!is.null(edgeDynamic)) tmeNames <- c('start', 'end') else tmeNames <- NULL
  
  # Generating weights
  if (all(is.null(edgesWeight))) {
    pastededges <- apply(edges[,c(2,1)], 1, paste, collapse="")
    for (i in 1:NROW(edges)) {
       edgesWeight <- c(
         edgesWeight, 
         sum(paste(edges[i,1:2], collapse="") %in% pastededges))
    }
  }
  else edgesWeight <- 0
  edges <- cbind(edges, edgesWeight+1)
  
  # Seting colnames
  colnames(edges) <- unlist(c("source", "target", tmeNames, attNames, "weight"))

  # EDGES
  xmlEdges <- newXMLNode(name='edges', parent=xmlGraph)
  .addNodesEdges(edges, xmlEdges, 'edge')
  results <- saveXML(xmlFile, encoding='UTF-8')
  class(results) <- 'gexf'
  
  if (is.na(output)) {
    return(results)
  } else {
    print(results, file=output)
    cat('GEXF graph written successfuly\n')
  }
}
