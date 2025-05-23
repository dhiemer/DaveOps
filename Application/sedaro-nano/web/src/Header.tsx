import React from 'react';
import { Flex } from '@radix-ui/themes';
import { Link } from 'react-router-dom';

const Header = () => {
  return (
    <Flex
      direction="column"
      align="center"
      style={{
        background: '#0753aaec',
        padding: '20px',
        boxShadow: '0 3px 8px rgba(0,0,0,0.2)',
      }}
    >
      <img
        src="/assets/daveops_top.png"
        alt="DaveOps Logo"
        style={{ maxHeight: '200px', width: 'auto' }}
      />
      <nav style={{ marginTop: '10px' }}>
        <Link to="/" style={linkStyle}>Home</Link>
        <Link to="/projects" style={linkStyle}>Projects</Link>
        <Link to="/resume" style={linkStyle}>Resume</Link>
        <Link to="/about" style={linkStyle}>About</Link>
        <Link to="/contact" style={linkStyle}>Contact</Link>
      </nav>
    </Flex>
  );
};

const linkStyle: React.CSSProperties = {
  margin: '0 15px',
  color: '#000',
  fontWeight: 'bold',
  textDecoration: 'none',
};

export default Header;
