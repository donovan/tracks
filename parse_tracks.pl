#!/usr/bin/perl

# Donovan Jones, January 2009
# comments and patches to cycle@gamma.net.nz

use strict;
use warnings;
use LWP::Simple;
use XML::LibXML;
use File::Basename;
use Data::Dumper;
use POSIX qw(ceil);

#TODO
# 1. add each area with green bike icon and set viewpoint in an areas top level dir,
# include the tracks.org.nz area content.

# 2. I think tracks like http://tracks.org.nz/track/show/228 NI XC Cup 2009
# should be in an 'event' top level like 'tracks' where they live ie:
# http://tracks.org.nz/event/show/1
# so for example the mt vic area would have both tracks and events under it,
# events like wild wellington etc would go in there,
# i may implement this for tracks i deem to be events

# 3. add usage and pod

# 4. deal with img and b tags in "right" content

# 5. add licence and author etc, gpl probabily

# 6. some of the most recent tracks with multiple paths are broken eg: 229 330
# only one path is being picked up

#7 addtrack reports

#8 make kmz file

# TODO
# add the rest of the data for the areas
my $areas = {
    '1' => {
        name        => 'Makara Peak',
        area_num    => '1',
        latitude    => '',
        longitude   => '',
        range       => '',
        heading     => '',
        tilt        => '',
    },
    '2' => {
        name        => 'Hawkins Hill',
        area_num    => '2',
        latitude    => '',
        longitude   => '',
        range       => '',
        heading     => '',
        tilt        => '',
    },
    '3' => {
        name        => 'Polhill',
        area_num    => '3',
        latitude    => '',
        longitude   => '',
        range       => '',
        heading     => '',
        tilt        => '',
    },
    '4' => {
        name        => 'Wrights Hill',
        area_num    => '4',
        latitude    => '',
        longitude   => '',
        range       => '',
        heading     => '',
        tilt        => '',
    },
    '5' => {
        name        => 'Mt Victoria',
        area_num    => '5',
        latitude    => '',
        longitude   => '',
        range       => '',
        heading     => '',
        tilt        => '',
    },
    '6' => {
        name        => 'Karori Park',
        area_num    => '6',
        latitude    => '',
        longitude   => '',
        range       => '',
        heading     => '',
        tilt        => '',
    },
    '7' => {
        name        => 'Western Hills',
        area_num    => '7',
        latitude    => '',
        longitude   => '',
        range       => '',
        heading     => '',
        tilt        => '',
    },
    '8' => {
        name        => 'Wainuiomata trail project',
        area_num    => '8',
        latitude    => '',
        longitude   => '',
        range       => '',
        heading     => '',
        tilt        => '',
    },
    '9' => {
        name        => 'Wainuiomata',
        area_num    => '9',
        latitude    => '',
        longitude   => '',
        range       => '',
        heading     => '',
        tilt        => '',
    },
    '10' => {
        name        => 'Pencarrow Lakes',
        area_num    => '10',
        latitude    => '',
        longitude   => '',
        range       => '',
        heading     => '',
        tilt        => '',
    },
    '11' => {
        name        => 'Belmont Regional Park',
        area_num    => '11',
        latitude    => '',
        longitude   => '',
        range       => '',
        heading     => '',
        tilt        => '',
    },
    '12' => {
        name        => 'Hutt River Trail',
        area_num    => '12',
        latitude    => '',
        longitude   => '',
        range       => '',
        heading     => '',
        tilt        => '',
    },
    '13' => {
        name        => 'Battle Hill',
        area_num    => '13',
        latitude    => '',
        longitude   => '',
        range       => '',
        heading     => '',
        tilt        => '',
    },
    '14' => {
        name        => 'Northern Suburbs',
        area_num    => '14',
        latitude    => '',
        longitude   => '',
        range       => '',
        heading     => '',
        tilt        => '',
    },
    '15' => {
        name        => 'Akatarawa Forest',
        area_num    => '15',
        latitude    => '',
        longitude   => '',
        range       => '',
        heading     => '',
        tilt        => '',
    },
    '16' => {
        name        => 'Pakuratahi Forest',
        area_num    => '16',
        latitude    => '',
        longitude   => '',
        range       => '',
        heading     => '',
        tilt        => '',
    },
    '17' => {
        name        => 'Hutt Valley',
        area_num    => '17',
        latitude    => '',
        longitude   => '',
        range       => '',
        heading     => '',
        tilt        => '',
    },
};

my %icons = (
    Beginner     => 'ylw',
    Easy         => 'grn',
    Intermediate => 'red',
    Advanced     => 'blu',
    Expert       => 'wht',
);

my %lv_icons = %icons;
$lv_icons{Intermediate} = 'pink';

my %colors = (
    Beginner     => 'ff00ffff',
    Easy         => 'ff009900',
    Intermediate => 'ff0000f9',
    Advanced     => 'ffff0000',
    Expert       => 'ff000000',
);

my $track_url = 'http://tracks.org.nz/track/show/';
my $site = 'http://tracks.org.nz';
my $data = {};
my $go = 1;
# change this if you're testing and don't want to download 230+ tracks every time you run the script
my $track_num = 1;
my $failed = 0;

# main loop which downloads and processes tracks.org.nz tracks
while ($go) {
    my $url = $track_url . $track_num;
    warn "-------------------------------------------------------------\n";
    warn "processing $url\n";

    my ($page, $kml_href, $kml);

    # TODO this is kinda dumb, could change this to two concurrent failures?
    $go = 0 if $failed == 3;

    unless (defined ($page = get $url)) {
        # track 15 is missing so far ...
        warn "could not get $url\n";
        $failed++;
        $track_num++;
        next;
    }

    # Create a parser object
    my $parser = XML::LibXML->new();
    $parser->recover(1);

    # Trap STDERR because the parser is quite verbose and annoying
    my $dom;
    {
        local *STDERR;
        open STDERR, '>', '/dev/null';
        # parse the page
        $dom = $parser->parse_html_string($page);
    }

    # Check that we got a dom object back
    die q{Parsing failed} unless defined $dom;

    # grab the url for the kml file
    foreach my $a ( $dom->findnodes(q{//p/a}) ) {
        if ($a->textContent eq 'Download GPS path') {
            $kml_href = $a->getAttribute('href');
        }
    }

    unless (defined $kml_href) {
        warn "could not get kml file for $url\n";
        $track_num++;
        next;
    }

    $kml_href = $site . $kml_href;
    my $filename = fileparse($kml_href, 'kml');
    # 1_1_6_35.
    $filename =~ s/\.$//;
    my ($area, $track) = (split /\_/, $filename)[-2, -1];
    my $area_name = $areas->{$area}{name};
    # if you get this warning you probably need to add a new area to @areas
    warn "\$area_name is undefined for track $url, check for a new area\n" unless defined $area_name;

    my %contents;
    my $key;
    # go through the paragraphs
    # get childnodes and then convert to string and concatenate
    foreach my $p ( $dom->findnodes(q{//div[@id='content']/p}) ) {
        my $id = $p->getAttribute('id');
        if ($id) {
            if ($id eq 'left') {
                $key = $p->textContent;
            }
            elsif ($id eq 'right') {
                my $text;
                foreach my $child ($p->childNodes) {
                    my $name = $child->nodeName;
                    if ($name eq '#text') {
                        $text .= $child->textContent;
                    }
                    elsif ($name eq 'br') {
                        $text .= $child->toString;
                    }
                    elsif ($name eq 'a') {
                        my $url = $child->getAttribute('href');
                        my $content = $child->textContent;
                        $url =~ s{ \A /track/show/ }{$site/track/show/}xms;
                        $text .= '<a href="' . $url . '">' . $content . '</a>';
                    }
                    # TODO deal with img tags (used in Altitude section)
                    # deal with b tags
                    else {
                        warn "new node that we dont know about yet: '$name', please fix\n";
                    }
                }
                $contents{$key} = $text;
            }
        }
    }

    $data->{$area_name}{$track_num}{content} .= "\n<table>\n";
    # TODO: pretty up the html, can you use css in google maps? otherwise inline styles ...
    #foreach my $key (keys %contents) {
    # we want the content ordered correctly
    foreach my $key ((
                      'Location',
                      'Overview',
                      'Grade',
                      'Access',
                      'Description',
                      'Getting there',
                      'Other notes',
                      'Length',
                      'Conditions',
                      'Last modified'
    )) {
        next unless $contents{$key};
        $data->{$area_name}{$track_num}{content} .= "    <tr>\n";
        $data->{$area_name}{$track_num}{content} .= "        <td>$key</td>\n";
        $data->{$area_name}{$track_num}{content} .= "        <td>$contents{$key}</td>\n";
        $data->{$area_name}{$track_num}{content} .= "    </tr>\n";
    }
    $data->{$area_name}{$track_num}{content} .= "    <tr>\n";
    $data->{$area_name}{$track_num}{content} .= "        <td>URL</td>\n";
    $data->{$area_name}{$track_num}{content} .= '        <td><a href="' . $url . '">' . $url . '</a></td>\n';
    $data->{$area_name}{$track_num}{content} .= "    </tr>\n";
    $data->{$area_name}{$track_num}{content} .= "\n</table>\n";

    # find the grade
    if ($contents{'Grade'} =~ m{ \A Beginner }xms) {
        $data->{$area_name}{$track_num}{grade} = 'Beginner';
    }
    elsif ($contents{'Grade'} =~ m{ \A Easy }xms) {
        $data->{$area_name}{$track_num}{grade} = 'Easy';
    }
    elsif ($contents{'Grade'} =~ m{ \A Intermediate }xms) {
        $data->{$area_name}{$track_num}{grade} = 'Intermediate';
    }
    elsif ($contents{'Grade'} =~ m{ \A Advanced }xms) {
        $data->{$area_name}{$track_num}{grade} = 'Advanced';
    }
    elsif ($contents{'Grade'} =~ m{ \A Expert }xms) {
        $data->{$area_name}{$track_num}{grade} = 'Expert';
    }

    #name
    $data->{$area_name}{$track_num}{name} = $contents{'Name'};

    # KML PARSING
    unless (defined ($kml = get $kml_href)) {
            die "could not get $kml_href\n";
    }

    # Create a parser object
    my $parser2 = XML::LibXML->new();
    $parser2->recover(1);

    # Trap STDERR because the parser is quite verbose and annoying
    my $dom2;
    {
        local *STDERR;
        open STDERR, '>', '/dev/null';
        # parse the page
        $dom2 = $parser2->parse_string($kml);
    }

    # Check that we got a dom object back
    die q{Parsing failed} unless defined $dom2;

    # TODO, this is ugly, find a LibXML function to find the ns uri ...
    # find the ns version
    my $version;
    if ( $dom2->toString =~ m{ xmlns="http://earth.google.com/kml/2.(\d)" }xms ) {
        $version = $1;
    }

    my $xc = XML::LibXML::XPathContext->new($dom2);
    $xc->registerNs('kml', "http://earth.google.com/kml/2.$version");

    my %coords;
    #<Placemark>
    #   <name>Sally Alley</name>
    #   <LineString>
    #       <coordinates>
    foreach my $node ( $xc->findnodes(q{//kml:coordinates}) ) {
        my $coords = $node->textContent;
        my $line_name;
        my $LineString = $node->parentNode;
        my $Placemark = $LineString->parentNode;
        foreach my $child ($Placemark->childNodes) {
            if ($child->nodeName eq 'name') {
                $line_name = $child->textContent;
            }
        }
        $coords{$line_name} = $coords;
    }

    # hash for storing the biggest middle value
    my $saved_middle = 0;

    # foreach line in a track
    foreach my $key (keys %coords ) {
        my @long;
        my @lat;

        foreach my $coord (split /\s+/, $coords{$key}) {
            my ($long, $lat) = split(/,/, $coord);
            push @lat, $lat if $lat;
            push @long, $long if $long;

        }

        my $middle = ceil((@long / 2) - 1);
        if ($middle > $saved_middle) {
            $data->{$area_name}{$track_num}{point} = "$long[$middle],$lat[$middle],0";
        };
        $saved_middle = $middle;

        $data->{$area_name}{$track_num}{coordinates}{$key}{lat} = [@lat];
        $data->{$area_name}{$track_num}{coordinates}{$key}{long} = [@long];
    }
    $track_num++;
}

#print Dumper($data);
#exit;

# output the kml doc
my $dom = XML::LibXML::Document->new('1.0', 'UTF-8');
my $kml = $dom->createElement('kml');
$kml->setAttribute('xmlns', 'http://earth.google.com/kml/2.2');
$dom->setDocumentElement($kml);

# create  and append top folder
my $top_folder = $dom->createElement('Folder');
$kml->appendChild($top_folder);

# populate top folder
my $top_name        = $dom->createElement('name');
my $top_open        = $dom->createElement('open');
my $top_description = $dom->createElement('description');
my $tracks_folder   = $dom->createElement('Folder');

$top_name->appendTextNode('top level');
$top_open->appendTextNode('1');

$top_folder->appendChild($top_name);
$top_folder->appendChild($top_open);
$top_folder->appendChild($tracks_folder);

# populate tracks folder
my $tracks_name         = $dom->createElement('name');
my $tracks_open         = $dom->createElement('open');
my $areas_folder        = $dom->createElement('Folder');

$tracks_name->appendTextNode('tracks');
$tracks_open->appendTextNode('1');

$tracks_folder->appendChild($tracks_name);
$tracks_folder->appendChild($tracks_open);
$tracks_folder->appendChild($areas_folder);

# populate areas folder
my $areas_name          = $dom->createElement('name');
my $areas_open          = $dom->createElement('open');

$areas_name->appendTextNode('areas');
$areas_open->appendTextNode('1');

$areas_folder->appendChild($areas_name);
$areas_folder->appendChild($areas_open);

# loop through the areas, sorted alphabetically
foreach my $area (sort keys %{$data}) {

    my $area_folder         = $dom->createElement('Folder');
    $areas_folder->appendChild($area_folder);

    my $area_name           = $dom->createElement('name');
    my $area_open           = $dom->createElement('open');

    $area_name->appendTextNode($area);
    $area_open->appendTextNode('1');

    $area_folder->appendChild($area_name);
    $area_folder->appendChild($area_open);

    # loop through the tracks, sort by track name
    foreach my $track (sort { $data->{$area}{$a}{name} cmp $data->{$area}{$b}{name} } keys %{$data->{$area}}) {

        my $track_document = $dom->createElement('Document');
        $area_folder->appendChild($track_document);

        my $track_name       = $dom->createElement('name');
        my $placemark        = $dom->createElement('Placemark');
        my $style            = $dom->createElement('Style');
        my $track_line_style = $dom->createElement('Style');

        $track_name->appendTextNode($data->{$area}{$track}{name});

        $track_document->appendChild($track_name);
        $track_document->appendChild($placemark);
        $track_document->appendChild($style);
        $track_document->appendChild($track_line_style);

        # do the style
        $style->setAttribute('id', $data->{$area}{$track}{grade});

        my $icon_style  = $dom->createElement('IconStyle');
        my $label_style = $dom->createElement('LabelStyle');
        my $list_style  = $dom->createElement('ListStyle');
        my $icon        = $dom->createElement('Icon');
        my $href        = $dom->createElement('href');
        my $scale       = $dom->createElement('scale');
        my $lv_href     = $dom->createElement('href');
        my $item_icon   = $dom->createElement('ItemIcon');
        my $hot_spot    = $dom->createElement('hotSpot');

        $hot_spot->setAttribute('x', '32');
        $hot_spot->setAttribute('y', '1');
        $hot_spot->setAttribute('xunits', 'pixels');
        $hot_spot->setAttribute('yunits', 'piyels');

        $href->appendTextNode('http://maps.google.com/mapfiles/kml/paddle/' . $icons{$data->{$area}{$track}{grade}} . '-blank.png');
        $lv_href->appendTextNode('http://maps.google.com/mapfiles/kml/paddle/' . $lv_icons{$data->{$area}{$track}{grade}} . '-blank-lv.png');
        $scale->appendTextNode('0.8');

        $style->appendChild($icon_style);
        $style->appendChild($label_style);
        $style->appendChild($list_style);
        $icon_style->appendChild($icon);
        $icon_style->appendChild($scale);
        $icon_style->appendChild($hot_spot);
        $label_style->appendChild($scale);
        $list_style->appendChild($item_icon);
        $icon->appendChild($href);
        $item_icon->appendChild($lv_href);

        # do the line style
        $track_line_style->setAttribute('id', 'TrackLineStyle');

        my $line_style = $dom->createElement('LineStyle');
        my $color      = $dom->createElement('color');
        my $width      = $dom->createElement('width');

        $color->appendTextNode($colors{$data->{$area}{$track}{grade}});
        $width->appendTextNode('1');

        $track_line_style->appendChild($line_style);
        $line_style->appendChild($width);
        $line_style->appendChild($color);

        # do the placemark
        my $placemark_name          = $dom->createElement('name');
        my $placemark_style         = $dom->createElement('styleUrl');
        my $placemark_point         = $dom->createElement('Point');
        my $placemark_description   = $dom->createElement('description');

        $placemark_name->appendTextNode($data->{$area}{$track}{name});
        $placemark_style->appendTextNode('#' . $data->{$area}{$track}{grade});

        $placemark->appendChild($placemark_name);
        $placemark->appendChild($placemark_style);
        $placemark->appendChild($placemark_point);
        $placemark->appendChild($placemark_description);

        # add placemark content
        my $cdata = $dom->createCDATASection($data->{$area}{$track}{content});
        $placemark_description->appendChild($cdata);

        # add placemark point
        my $coordinates = $dom->createElement('coordinates');
        $coordinates->appendTextNode($data->{$area}{$track}{point});
        $placemark_point->appendChild($coordinates);

        # loop through paths here
        foreach my $path (keys %{$data->{$area}{$track}{coordinates}}) {

            my $path_placemark = $dom->createElement('Placemark');
            $track_document->appendChild($path_placemark);

            my $pp_name         = $dom->createElement('name');
            my $pp_style        = $dom->createElement('styleUrl');
            my $pp_linestring   = $dom->createElement('LineString');

            $pp_name->appendTextNode($path);
            $pp_style->appendTextNode('#TrackLineStyle');

            $path_placemark->appendChild($pp_name);
            $path_placemark->appendChild($pp_style);
            $path_placemark->appendChild($pp_linestring);

            my $tessellate  = $dom->createElement('tessellate');
            my $alt         = $dom->createElement('altitudeMode');
            my $coordinates = $dom->createElement('coordinates');

            $tessellate->appendTextNode('1');
            $alt->appendTextNode('clampToGround');

            # probably should have left the coords in a single chunk, oh well ...
            my $count = 0;
            my $ll_chunk;
            foreach my $lat (@{$data->{$area}{$track}{coordinates}{$path}{lat}}) {
                $ll_chunk .= ${$data->{$area}{$track}{coordinates}{$path}{long}}[$count] . ',' . $lat . ",0\n";
                $count++;
            }

            $coordinates->appendTextNode($ll_chunk);

            $pp_linestring->appendChild($tessellate);
            $pp_linestring->appendChild($alt);
            $pp_linestring->appendChild($coordinates);

        }

    }

}

print $dom->toString(1);
