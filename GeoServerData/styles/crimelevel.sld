<sld:UserStyle xmlns="http://www.opengis.net/sld" xmlns:sld="http://www.opengis.net/sld" xmlns:ogc="http://www.opengis.net/ogc" xmlns:gml="http://www.opengis.net/gml">
  <sld:Name>Default Styler</sld:Name>
  <sld:Title/>
  <sld:FeatureTypeStyle>
    <sld:Name>name</sld:Name>
    <sld:Rule>
        <Name>No crime</Name>
        <Title>Less than 100 incidents</Title>
        <ogc:Filter>
            <ogc:PropertyIsLessThan>
                <ogc:PropertyName>crimecount</ogc:PropertyName>
                <ogc:Literal>100</ogc:Literal>
            </ogc:PropertyIsLessThan>
        </ogc:Filter>
        <sld:PolygonSymbolizer>
          <sld:Fill>
            <sld:CssParameter name="fill">#73CEFF</sld:CssParameter>
            <sld:CssParameter name="opacity">0.35</sld:CssParameter>
          </sld:Fill>
        </sld:PolygonSymbolizer>
    </sld:Rule>
    <sld:Rule>
        <Name>Little crime</Name>
        <Title>Less than 200 incidents</Title>
        <ogc:Filter>
            <ogc:PropertyIsBetween>
                <ogc:PropertyName>crimecount</ogc:PropertyName>
                <ogc:LowerBoundary>
                    <ogc:Literal>100</ogc:Literal>
                </ogc:LowerBoundary>
                <ogc:UpperBoundary>
                    <ogc:Literal>200</ogc:Literal>
                </ogc:UpperBoundary>
            </ogc:PropertyIsBetween>
        </ogc:Filter>
        <sld:PolygonSymbolizer>
          <sld:Fill>
            <sld:CssParameter name="fill">#BBFFFF</sld:CssParameter>
            <sld:CssParameter name="opacity">0.35</sld:CssParameter>
          </sld:Fill>
        </sld:PolygonSymbolizer>
    </sld:Rule>
    <sld:Rule>
        <Name>Medium crime</Name>
        <Title>Less than 500 incidents</Title>
        <ogc:Filter>
            <ogc:PropertyIsBetween>
                <ogc:PropertyName>crimecount</ogc:PropertyName>
                <ogc:LowerBoundary>
                    <ogc:Literal>200</ogc:Literal>
                </ogc:LowerBoundary>
                <ogc:UpperBoundary>
                    <ogc:Literal>500</ogc:Literal>
                </ogc:UpperBoundary>
            </ogc:PropertyIsBetween>
        </ogc:Filter>
        <sld:PolygonSymbolizer>
          <sld:Fill>
            <sld:CssParameter name="fill">#FFF365</sld:CssParameter>
            <sld:CssParameter name="opacity">0.35</sld:CssParameter>
          </sld:Fill>
        </sld:PolygonSymbolizer>
    </sld:Rule>
    <sld:Rule>
        <Name>Heavy crime</Name>
        <Title>Less than 1000 incidents</Title>
        <ogc:Filter>
            <ogc:PropertyIsBetween>
                <ogc:PropertyName>crimecount</ogc:PropertyName>
                <ogc:LowerBoundary>
                    <ogc:Literal>500</ogc:Literal>
                </ogc:LowerBoundary>
                <ogc:UpperBoundary>
                    <ogc:Literal>1000</ogc:Literal>
                </ogc:UpperBoundary>
            </ogc:PropertyIsBetween>
        </ogc:Filter>
        <sld:PolygonSymbolizer>
          <sld:Fill>
            <sld:CssParameter name="fill">#FF9B1E</sld:CssParameter>
            <sld:CssParameter name="opacity">0.35</sld:CssParameter>
          </sld:Fill>
        </sld:PolygonSymbolizer>
    </sld:Rule>
    <sld:Rule>
        <Name>Very heavy crime</Name>
        <Title>More than 1000 incidents</Title>
        <ogc:Filter>
            <ogc:PropertyIsGreaterThan>
                <ogc:PropertyName>crimecount</ogc:PropertyName>
                <ogc:Literal>1000</ogc:Literal>
            </ogc:PropertyIsGreaterThan>
        </ogc:Filter>
        <sld:PolygonSymbolizer>
          <sld:Fill>
            <sld:CssParameter name="fill">#FF1604</sld:CssParameter>
            <sld:CssParameter name="opacity">0.35</sld:CssParameter>
          </sld:Fill>
        </sld:PolygonSymbolizer>
    </sld:Rule>
    <sld:Rule>
        <Name>Postcode</Name>
        <Title>Postcode of the area</Title>
        <sld:PolygonSymbolizer>
            <sld:Stroke>
                <sld:CssParameter name="stroke">#000000</sld:CssParameter>
                <sld:CssParameter name="stroke-width">1</sld:CssParameter>
                <sld:CssParameter name="stroke-opacity">0.5</sld:CssParameter>
            </sld:Stroke>
        </sld:PolygonSymbolizer>
        <sld:TextSymbolizer>
            <sld:Label>
                <ogc:PropertyName>name</ogc:PropertyName>
            </sld:Label>
            <sld:Font>
                <sld:CssParameter name="font-family">Helvetica</sld:CssParameter>
                <sld:CssParameter name="font-size">14.0</sld:CssParameter>
                <sld:CssParameter name="font-style">normal</sld:CssParameter>
                <sld:CssParameter name="font-weight">normal</sld:CssParameter>
            </sld:Font>
            <sld:Halo>
                <sld:Radius>2.0</sld:Radius>
                <sld:Fill>
                    <sld:CssParameter name="fill">#FFFFFF</sld:CssParameter>
                </sld:Fill>
            </sld:Halo>
            <sld:Fill>
                <sld:CssParameter name="fill">#000000</sld:CssParameter>
            </sld:Fill>
        </sld:TextSymbolizer>
    </sld:Rule>
  </sld:FeatureTypeStyle>
</sld:UserStyle>