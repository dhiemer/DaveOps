import { Form, FormField, FormLabel } from '@radix-ui/react-form';
import { Button, Card, Flex, Heading, Separator, TextField } from '@radix-ui/themes';
import _ from 'lodash';
import React, { useCallback, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Routes } from 'routes';
import Header from './Header';

type FormValue = number | '';
interface FormData {
  Body1: {
    position: { x: FormValue; y: FormValue; z: FormValue };
    velocity: { x: FormValue; y: FormValue; z: FormValue };
    mass: FormValue;
  };
  Body2: {
    position: { x: FormValue; y: FormValue; z: FormValue };
    velocity: { x: FormValue; y: FormValue; z: FormValue };
    mass: FormValue;
  };
}

const SimulateForm: React.FC = () => {
  const navigate = useNavigate();

  const [formData, setFormData] = useState<FormData>({
    Body1: { position: { x: -0.73, y: 0, z: 0 }, velocity: { x: 0, y: -0.0015, z: 0 }, mass: 1 },
    Body2: { position: { x: 60.34, y: 0, z: 0 }, velocity: { x: 0, y: 0.13, z: 0 }, mass: 0.0123 },
  });

  const handleChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    let newValue: FormValue = value === '' ? '' : parseFloat(value);
    setFormData((prev) => _.set({ ...prev }, name, newValue));
  }, []);

  const handleSubmit = useCallback(
    async (e: React.FormEvent) => {
      e.preventDefault();
      try {
        const response = await fetch('https://sedaro-nano.daveops.pro/api/simulation', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(formData),
        });
        if (!response.ok) throw new Error('Network response was not ok');
        navigate(Routes.SIMULATION);
      } catch (error) {
        console.error('Error:', error);
      }
    },
    [formData]
  );

  return (
    <>
      <Header />
      <div
        style={{
          position: 'absolute',
          top: '5%',
          left: 'calc(50% - 200px)',
          overflow: 'scroll',
        }}
      >
        <Card style={{ width: '400px' }}>
          <Heading as="h2" size="4" weight="bold" mb="4">
            Run a Simulation
          </Heading>
          <Link to={Routes.SIMULATION}>View previous simulation</Link>
          <Separator size="4" my="5" />
          <Form onSubmit={handleSubmit}>
            <Heading as="h3" size="3" weight="bold">Body1</Heading>
            {['x', 'y', 'z'].map((axis) => (
              <FormField key={axis} name={`Body1.position.${axis}`}>
                <FormLabel htmlFor={`Body1.position.${axis}`}>Initial {axis.toUpperCase()}-position</FormLabel>
                <TextField.Root
                  type="number"
                  id={`Body1.position.${axis}`}
                  name={`Body1.position.${axis}`}
                  value={formData.Body1.position[axis]}
                  onChange={handleChange}
                  required
                />
              </FormField>
            ))}
            {['x', 'y', 'z'].map((axis) => (
              <FormField key={axis} name={`Body1.velocity.${axis}`}>
                <FormLabel htmlFor={`Body1.velocity.${axis}`}>Initial {axis.toUpperCase()}-velocity</FormLabel>
                <TextField.Root
                  type="number"
                  id={`Body1.velocity.${axis}`}
                  name={`Body1.velocity.${axis}`}
                  value={formData.Body1.velocity[axis]}
                  onChange={handleChange}
                  required
                />
              </FormField>
            ))}
            <FormField name="Body1.mass">
              <FormLabel htmlFor="Body1.mass">Mass</FormLabel>
              <TextField.Root
                type="number"
                id="Body1.mass"
                name="Body1.mass"
                value={formData.Body1.mass}
                onChange={handleChange}
                required
              />
            </FormField>

            <Heading as="h3" size="3" weight="bold" mt="4">Body2</Heading>
            {['x', 'y', 'z'].map((axis) => (
              <FormField key={axis} name={`Body2.position.${axis}`}>
                <FormLabel htmlFor={`Body2.position.${axis}`}>Initial {axis.toUpperCase()}-position</FormLabel>
                <TextField.Root
                  type="number"
                  id={`Body2.position.${axis}`}
                  name={`Body2.position.${axis}`}
                  value={formData.Body2.position[axis]}
                  onChange={handleChange}
                  required
                />
              </FormField>
            ))}
            {['x', 'y', 'z'].map((axis) => (
              <FormField key={axis} name={`Body2.velocity.${axis}`}>
                <FormLabel htmlFor={`Body2.velocity.${axis}`}>Initial {axis.toUpperCase()}-velocity</FormLabel>
                <TextField.Root
                  type="number"
                  id={`Body2.velocity.${axis}`}
                  name={`Body2.velocity.${axis}`}
                  value={formData.Body2.velocity[axis]}
                  onChange={handleChange}
                  required
                />
              </FormField>
            ))}
            <FormField name="Body2.mass">
              <FormLabel htmlFor="Body2.mass">Mass</FormLabel>
              <TextField.Root
                type="number"
                id="Body2.mass"
                name="Body2.mass"
                value={formData.Body2.mass}
                onChange={handleChange}
                required
              />
            </FormField>

            <Flex justify="center" m="5">
              <Button type="submit">Submit</Button>
            </Flex>
          </Form>
        </Card>
      </div>
    </>
  );
};

export default SimulateForm;
